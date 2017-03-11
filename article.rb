#!/usr/bin/env ruby

require 'colorize'
require 'highline/import'
require 'open3'
require 'fileutils'
require 'pdf-reader'

require 'open3'

require "i18n"
I18n.config.available_locales = :en

require './prompt'

def apply_range_list(ranges:, iterable:)
  selection = []
  ranges.each do |range|
    selection << iterable[range]
  end
  selection
end

def select_lines(
  question: 'Input a list of line ranges: ',
  lead: '0..1',
  lines: []
)
  lines.each_with_index do |line, index|
    puts "#{index}:  ".green + line.rstrip.blue
  end

  puts lead

  ranges = RangesPrompt.new(
    question: question.blue,
    lead: lead
  ).ask

  apply_range_list(ranges: ranges, iterable: lines)
end

begin
  # Get filename and check existence.
  filename = ARGV[0]
  raise 'I need a filename, bub.' if filename.nil?
  raise 'File does not exist, bub.' unless File.exist? filename

  # Clean filename and show it.
  filename = File.absolute_path ARGV[0]
  puts "File found:\n  #{filename}"

  # Select the page range for extraction.
  page_range = QualifiedRangePrompt.new(
    question: "Input a page range for extraction: ".blue,
    lead: '0[0..9]'
  ).ask

  # puts page_range.inspect.yellow


  # Read file and get text from first page removing empty lines.
  reader = PDF::Reader.new filename
  txt = reader.pages[2..4]

  # puts txt.inspect

  lines = []
  page_range.each do |spec|
    reader.pages[spec[:pages]].each do |page|
      lines.concat page.text.gsub(/\n+/,"\n").lines[spec[:lines]]
    end
  end

  lines.each_with_index do |line, index|
    line_number = index.to_s.rjust((lines.length-1).to_s.length)
    puts "#{line_number}: ".green + line.rstrip.blue
  end

  # exit
  # stdout, stderr, status = Open3.capture3(
  #   'pdftotext', '-f', page_range.first.to_s, '-l', page_range.last.to_s, filename, '-'
  # )
  # raise "There was an error parsing the PDF, bub." unless status.success?
  # extracted_text = stdout.gsub(/\n+/, "\n")

  # Check whether there actually is text.
  # raise "There is no text to fetch, bub." if extracted_text.empty?



  lines_range = RangePrompt.new(
    question: "Input lines, bub: ".blue,
    lead: '0..1'
  ).ask

  header = lines[lines_range].join

  # Prepare search string from matched header.
  search_string = header.gsub(/\s+/, ' ').strip
  search_string = I18n.transliterate search_string
  search_string = Prompt.new(
    question: 'Confirm search string: '.blue,
    lead: search_string,
    regexp: //
  ).ask

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
  safe_title = title.downcase.gsub(/[^A-Za-z0-9 ]/, ' ').strip.gsub(/\s+/, '_')

  # Extract and format authors.
  authors = result.scan(/%A (.*),/).map(&:first).map { |a| I18n.transliterate a }
  safe_authors = authors.uniq.join('_').upcase.gsub(/\s+/, '_')

  # Format new filename.
  puts safe_authors
  puts safe_title
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



