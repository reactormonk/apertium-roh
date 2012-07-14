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
require 'plymouth'
require 'shellwords'

class LTProc
  # this generates file.lr and file.rl in the directory
  def initialize(dix, direction, parameters = nil)
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

if File.exists? 'analyze'
  describe "analyzer" do
    proc = LTProc.new(DIX, 'lr')
    File.read('analyze').each_line do |line|
      input, output = *line.strip.split(";").map(&:strip)
      it "should analyze #{input}" do
        proc.process(input).chomp('$').split("/").must_include output
      end if input
    end
  end
end

if File.exists? 'generate'
  describe "generator" do
    proc = LTProc.new(DIX, 'rl', '-g')
    File.read('generate').each_line do |line|
      input, output = *line.strip.split(";").map(&:strip)
      it "should generate #{input}" do
        proc.process(input).must_equal output
      end if input
    end
  end
end
