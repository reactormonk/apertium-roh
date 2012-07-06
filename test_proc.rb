#!/usr/bin/env ruby
# This script expects three files:
# - dictionary (place path below)
# - data files:
#   - analyze
#   - generate
# The data files are as following:
# input ; output \n
# input ; output \n
# ...
#
# run via ruby <this file>
# or chmod +x <this file> and ./<this file>

# path to dix here 
DIX = 'generated.dix'

require 'minitest/spec'
require 'minitest/autorun'
require 'shellwords'

class LTProc
  # this generates file.lr and file.rl in the directory
  def initialize(dix, direction, parameters)
    system ['lt-comp', direction, dix, dix + "." + direction].shelljoin
    @proc = IO.popen(['lt-proc', '-z', parameters, dix + "." + direction].compact, 'r+')
    @proc.sync = true
  end

  def process(word)
    @proc.write(word + " \x0")
    @proc.flush
    @proc.gets("\x0").strip
  end
end

[['analyze', 'lr', nil], ['generate', 'rl', '-g']].each do |(type, direction, parameters)|
  describe "#{type}r" do
    if File.exists? type
      proc = LTProc.new(DIX, direction, parameters)
      # expectes either 'analyze' or 'generate'
      File.read(type).each_line do |line|
        input, output = *line.strip.split(";").map(&:strip)
        it "should #{type} #{input}" do
          proc.process(input).must_equal output
        end if input
      end
    end
  end
end
