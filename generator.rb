require 'nokogiri'
require 'erb'
require 'pry'

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
    m = vb_root.match /(.*)(#{Regexp.union(@from, @to)})([^aieou]*)$/
    m[1] + @invert[m[2]] + m[3]
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

if $0 == __FILE__
  document = Nokogiri::XML(File.read('basics.metadix'))

  VCHANGE = ERB.new <<-DATA
<e lm="<%=verb.root%>"><i><%=verb.changed%></i><par n="0__vblex"/></e>
<e lm="<%=verb.root%>"><i><%=verb.root%></i><par n="<%=verb.type%>1__vblex"/></e>
DATA

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
      "<e lm='%s'><i>%s</i><par n='%s__vblex'/></e>" % [verb.verb, verb.root, verb.type]
    end
  end.join("\n")

  [vbchange, vblex].each do |vb| document.at_css("#main").add_child vb end

  puts document.to_xml
end
