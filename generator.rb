# encoding: utf-8
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

class ComplexVerb < Verb
  def initialize(verb, root, changed)
    super(verb)
    @root, @changed = root, changed
  end

  attr :root, :changed
end

# need type for 0__vblex too, see sur
VCHANGE = ERB.new <<-DATA
<e lm="<%=verb.verb%>"><p><l><%=verb.changed%></l><r><%=verb.verb%></r></p><par n="<%=verb.type%>0__vblex"/></e>
<e lm="<%=verb.verb%>"><p><l><%=verb.root%></l><r><%=verb.verb%></r></p><par n="<%=verb.type%>1__vblex"/></e>
DATA
# `-sch-` type words inflect differently in sur/prs
VSCH = ERB.new <<-DATA
<e lm="<%=verb.verb%>"><p><l><%=verb.changed%></l><r><%=verb.verb%></r></p><par n="<%=verb.type%>-sch0__vblex"/></e>
<e lm="<%=verb.verb%>"><p><l><%=verb.root%></l><r><%=verb.verb%></r></p><par n="<%=verb.type%>-sch1__vblex"/></e>
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
VIRREG = ERB.new <<-DATA
<e lm="<%=verb.verb%>"><p><l><%=verb.changed%></l><r><%=verb.verb%></r></p><par n="v_pri_<%=verb.type%>"/></e>
<e lm="<%=verb.verb%>"><p><l><%=verb.root%></l><r><%=verb.verb%></r></p><par n="<%=verb.type%>1_irreg__vblex"/></e>
DATA

def generate
  # add strings here - added to the section
  verbs =  []
  # add strings here - added to the pardefs
  pardefs = []
  document = Nokogiri::XML(File.read('basics.dix', encoding: 'utf-8'))

  ['irregular.dix', 'additions.dix'].each do |name|
    if File.exist? name
      verbs << File.read(name)
    end
  end

  # TODO: 106/107

  verbs << Dir['vblex/*-*'].flat_map do |file|
    from, to = File.basename(file).split('-')
    File.read(file).each_line.map do |verb|
      verb = VCVerb.new(verb, from, to)
      VCHANGE.result(binding)
    end
  end.join("\n")

  verbs << File.read('vblex/simple').each_line.map do |verb|
    verb = Verb.new verb
    VBLEX.result(binding)
  end.join("\n")

  [['vblex/complex', VCHANGE], ['vblex/irregular', VIRREG]].each do |(file, template)|
    if File.exist?(file)
      verbs << File.read(file).each_line.map do |line|
        verb = ComplexVerb.new(*line.split(";").map(&:strip))
        template.result(binding)
      end.join("\n")
    end
  end

  proc do
    # This is only for Sursilvan, based on the existence of `vblex/sch`
    file = 'vblex/sch'
    if File.exist?(file)
      verbs << File.read(file).each_line.map do |line|
        verb = VCVerb.new(line.strip, "", "")
        infix = {'e' => 'e', 'a' => 'e', 'ai' => 'e', 'i' => 'i'}[verb.type]
        verb.instance_variable_set(:@to, infix + "sch")
        VSCH.result(binding)
      end.join("\n")
    end
  end.call

  # require 'pry'
  # binding.pry
  verbs.each do |vb| vb and document.at_css("#main").add_child vb end
  pardefs.each do |pardef| pardef and document.at_css("pardefs").add_child pardef end

  File.open('generated.dix', 'w') {|file| file.puts document.to_xml(encoding: 'utf-8') }
end

if $0 == __FILE__
  generate
end
