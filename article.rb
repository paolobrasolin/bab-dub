#!/usr/bin/env ruby

require 'colorize'
require 'highline/import'
require 'open3'
require 'fileutils'
require 'pdf-reader'

require "i18n"
I18n.config.available_locales = :en

def select_lines(
  query: 'Input a list of line ranges: ',
  default: '0..1',
  lines: []
)
  lines.each_with_index do |line, index|
    puts "#{index}:  ".green + line.rstrip.blue
  end

  ranges_string = ask(query) do |input|
    input.default = default
    input.validate = /(\d+\.\.\d+|\d+)(\s*,\s*\d+\.\.\d+|\d+)*/
  end

  ranges = ranges_string.split(/\s*,\s*/).map do |range|
    if range =~ /\d+\.\.\d+/
      Range.new(*range.split('..').map(&:to_i))
    elsif range =~ /\d+/
      range.to_i
    else
      raise 'There definitely is a bug, bub.'
    end
  end

  selected_lines = []
  ranges.each do |range|
    selected_lines << lines[range]
  end

  selected_lines
end

begin
  # Get filename and check existence.
  filename = ARGV[0]
  raise 'File does not exist, bub.' unless File.exist? filename

  # Clean filename and show it.
  filename = File.absolute_path ARGV[0]
  puts "Filename:\n  #{filename}"

  # Read file and get text from first page removing empty lines.
  reader = PDF::Reader.new filename
  front_page_text = reader.page(1).text.gsub(/\n+/, "\n")

  # Check whether there actually is text.
  raise "There is no text to fetch, bub." if front_page_text.empty?

  # Search and fetch some kind of header on first page.
  # if (/abstract/i).match(front_page_text)
  #   # Get everything before abstract.
  #   header = front_page_text.split(/abstract/i).first
  # elsif (/@/).match(front_page_text)
  #   # Cut everything after last email.
  #   header = front_page_text.rpartition(/@\S+/).first(2).join
  # else

  puts "Head of first page:"
  header = front_page_text.lines
  header = select_lines(lines: header[0,9]).join
  # header = header.join

  # end

  # Prepare search string from matched header.
  search_string = header.gsub(/\s+/, ' ').strip
  search_string = I18n.transliterate search_string
  puts "Search string:\n  " + search_string.scan(/.{1,78}/).join("\n  ")

  # exit

  # Use scholar.py to fetch the best (first) match.
  result, stderr, status = Open3.capture3(
    'python2.7',
    'scholar.py/scholar.py',
    '--citation=en',
    '-c 1',
    "--all=\"#{search_string}\""
  )
  raise stderr unless status.success?
  puts "Best result:\n  " + result.gsub(/\n/, "\n  ").strip

  # Extract and format title.
  title = I18n.transliterate result.scan(/%T (.*)/).first.first
  safe_title = title.downcase.gsub(/[^A-Za-z0-9 ]/, '').gsub(/\s+/, '_')

  # Extract and format authors.
  authors = result.scan(/%A (.*),/).map(&:first).map { |a| I18n.transliterate a }
  safe_authors = authors.uniq.join('_').upcase

  # Format new filename.
  safe_filename = "#{safe_title}_#{safe_authors}.pdf"
  puts "New filename:\n  " + safe_filename

  # Ask wheter to rename file.
  confirm = ask("Rename the article? [Y/N] ") do |yn|
    yn.limit = 1
    yn.validate = /[yn]/i
  end

  # Conditionally rename file.
  if confirm.downcase == 'y'
    dirname = File.dirname filename
    FileUtils.mkdir_p File.join(dirname, 'dubbed')
    File.rename filename, File.join(dirname, 'dubbed', safe_filename)
    puts 'Done!'
  else
    puts 'Ok, bub.'
  end
rescue StandardError => error
  # If there's any error just drop the gun.
  puts error.to_s.red
  exit
end



