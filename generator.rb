require 'nokogiri'
require 'erb'

class Verb
  def initialize(verb)
    @verb = verb.strip
  end
  attr :verb

  TYPES = %w(a ai e i)
  def type
    verb[/(#{Regexp.union(TYPES)})r$/,1]
  end

  def root
    verb[/(.*)#{type}r$/,1]
  end
end

class VCVerb < Verb
  def initialize(verb, from, to)
    super(verb)
    @from, @to = from, to
    @invert = {@from => @to, @to => @from}
  end

  # the root can be in either form, but the shift is always at the
  # second-leftmost vocal.

  alias vb_root root
  def change
    if [@from, @to].any?(&:empty?) # insert only
      vb_root + [@from, @to].max_by {|e| e.size} # see which one is the insert one
    else
      m = vb_root.match /(.*?)(#{Regexp.union(@from, @to)})([^aieou]*)$/
      m[1] + @invert[m[2]] + m[3]
    end
  end

  def inverted?
    vb_root =~ /#{@to}[^aieou]*$/
  end

  def root
    inverted? ? change : vb_root
  end

  def changed
    inverted? ? vb_root : change
  end

  def inf
    @verb
  end
end


VCHANGE = ERB.new <<-DATA
<e lm="<%=verb.verb%>"><p><l><%=verb.changed%></l><r><%=verb.verb%></r></p><par n="0__vblex"/></e>
<e lm="<%=verb.verb%>"><p><l><%=verb.root%></l><r><%=verb.verb%></r></p><par n="<%=verb.type%>1__vblex"/></e>
DATA
VBLEX = ERB.new <<-DATA
<e lm='<%=verb.verb%>'>
  <p>
    <l><%=verb.root%></l>
    <r><%=verb.verb%></r>
  </p>
  <par n='<%=verb.type%>__vblex'/>
</e>
DATA


def generate
  irregular = Nokogiri::XML(File.read('irregular.dix'))
  document = Nokogiri::XML(File.read('basics.dix'))

   vbchange = Dir['vblex/*-*'].flat_map do |file|
    from, to = File.basename(file).split('-')
    File.read(file).each_line.map do |verb|
      verb = VCVerb.new(verb, from, to)
      VCHANGE.result(binding)
    end
  end.join("\n")

  vblex = Dir['vblex/simple'].flat_map do |file|
    type = File.basename file
    File.read(file).each_line.map do |verb|
      verb = Verb.new verb
      VBLEX.result(binding)
    end
  end.join("\n")

  vbirreg = irregular.css("#main").children
  pars = irregular.css("pardef")

  [vbirreg, vbchange, vblex].each do |vb| document.at_css("#main").add_child vb end

  document.at_css("pardefs").add_child pars

  File.open('generated.dix', 'w') {|file| file.puts document.to_xml(encoding: 'utf-8') }
end

if $0 == __FILE__
  generate
end
