#!/usr/bin/env ruby

require 'readline'
require 'colorize'

class Prompt
  def initialize(
    question:,
    lead: '',
    regexp: //,
    error: 'Invalid input. Please fix it.'.red
  )
    @question = question
    @lead = lead
    @regexp = regexp
    @error = error
  end

  def ask
    Readline.pre_input_hook = lambda do
      Readline.insert_text @lead
      Readline.redisplay
      Readline.pre_input_hook = nil
    end

    @input = Readline.readline @question, false

    return parsed if validates?

    puts @error
    @lead = @input
    ask
  end

  def parsed
    @input
  end

  def validates?
    @input =~ @regexp
  end
end


class RangesPrompt < Prompt
  def initialize(
    question: 'Input a list of ranges: '.blue,
    lead: '0..1',
    regexp: /^\s*(\d+\.\.\d+|\d+)(\s*,\s*(\d+\.\.\d+|\d+))*\s*$/
  )
    super
  end

  def parsed
    @input.split(/\s*,\s*/).map do |range|
      if range =~ /\d+\.\.\d+/
        Range.new(*range.split('..').map(&:to_i))
      elsif range =~ /\d+/
        range.to_i
      else
        raise 'There definitely is a bug, bub.'
      end
    end
  end
end


class RangePrompt < Prompt
  def initialize(
    question: 'Input a list of ranges: '.blue,
    lead: '0..1',
    regexp: /^\s*(\d+\.\.\d+|\d+)\s*$/
  )
    super
  end

  def parsed
    if @input =~ /\d+\.\.\d+/
      Range.new(*@input.split('..').map(&:to_i))
    elsif @input =~ /\d+/
      Range.new @input.to_i, @input.to_i
    else
      raise 'There definitely is a bug, bub.'
    end
  end
end

class QualifiedRangePrompt < Prompt
  N = /-?\d+/
  R = /#{N}\.\.#{N}/
  M = /#{R}|#{N}/ # order is important
  L = /#{M}(?:,#{M})*/

  X = /#{M}(?:\[#{L}\])?/
  Y = /#{X}(?:,#{X})*/

  def initialize(
    question: 'Input a list of ranges: '.blue,
    lead: '0..1',
    regexp: /^#{Y}$/
  )
    super
  end

  def parsed
    pages = []
    @input.scan(/(#{M})(?:\[(#{L})\])?/).each do |spec|
      page_spec, line_specs = spec
      line_specs ||= "0..-1" # no line range => full page
      page_range = spec_to_range page_spec
      line_specs.scan(/(#{M})/).map(&:first).each do |line_spec|
        line_range = spec_to_range line_spec
        pages << {pages: page_range, lines: line_range}
      end
    end
    pages
  end

  private

    def spec_to_range(spec)
      if spec =~ /^(#{N})\.\.(#{N})$/
        extrema = $~.captures
      elsif spec =~ /^(#{N})$/
        extrema = $~.captures*2
      end
      Range.new(*extrema.map(&:to_i))
    end
end
