#!/usr/bin/env ruby

require 'colorize'
require 'highline/import'
require 'open3'
require 'fileutils'

require 'progress_bar'
# class Array
#   include ProgressBar::WithProgress
# end

require 'open3'

require "i18n"
I18n.config.available_locales = :en

require './prompt'
require './extract'

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


def check_filename(filename)
  # Get filename and check existence.
  raise 'I need a filename, bub.' if filename.nil?
  raise 'File does not exist, bub.' unless File.exist? filename

  # Clean filename and show it.
  filepath = File.absolute_path ARGV[0]
  puts 'File found: '.green + filepath.to_s.blue

  # Return full checked path.
  filepath
end

begin
  filename = check_filename ARGV[0]

  extraction_ranges = QualifiedRangePrompt.new(
    question: "Input extraction ranges: ".blue,
    lead: '0[0..9]'
  ).ask

  page_set = []
  extraction_ranges.each { |s| page_set.concat s[:pages].to_a }
  page_set.sort!.uniq!

  content = extract_txt filename: filename, pageset: page_set

  content_is_empty = content.join.gsub(/[[:space:]]/, '').empty?

  if content_is_empty
    puts "No text found!".red
    should_try_ocr = BoolPrompt.new(
      question: "This might be a scan. Should I try with OCR? ".blue,
      lead: 'y'
    ).ask
  else
    puts "Text extracted!".green
  end

  if should_try_ocr
    content = extract_ocr filename: filename, pageset: page_set
    content_is_empty = content.join.gsub(/[[:space:]]/, '').empty?
    raise "Still no text found! Aborting the mission.".red if content_is_empty
    puts "Text extracted!".green
  else
    puts "Ok bub. Bye!".green
    exit
  end

  # At this point either we have aborted or we have content.

  lines = []
  extraction_ranges.each do |spec|
    content[spec[:pages]].each do |page|
      lines.concat page.lines[spec[:lines]]
    end
  end

  lines.each_with_index do |line, index|
    line_number = index.to_s.rjust((lines.length-1).to_s.length)
    puts "#{line_number}: ".green + line.rstrip.blue
  end

  lines_ranges = UnqualifiedRangePrompt.new(
    question: "Input lines, bub: ".blue,
    lead: '0..1'
  ).ask

  q_lines = []
  lines_ranges.each do |range|
    q_lines << lines[range]
  end

  header = q_lines.join

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
  query_result = result.strip

  if query_result.empty?
    puts "No result!".red
    should_rename_file = BoolPrompt.new(
      question: "Wanna rename the file manually? ".blue,
      lead: 'n'
    ).ask
  else
    puts "Best Google Scholar result:\n  " + query_result

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
    puts "Proposed filename:\n  " + safe_filename

    # Ask wheter to rename file.
    should_rename_file = BoolPrompt.new(
      question: "Wanna rename the file? ".blue,
      lead: 'y'
    ).ask
  end

  unless should_rename_file
    puts 'Ok bub. Bye!'.green
    exit
  end

  new_filename = Prompt.new(
    question: 'Confirm new filename: '.blue,
    lead: safe_filename || search_string,
    regexp: //
  ).ask

  exit

  # Conditionally rename file.
  if should_rename_file
    dirname = File.dirname filename
    FileUtils.mkdir_p File.join(dirname, 'dubbed')
    File.rename filename, File.join(dirname, 'dubbed', new_filename)
    puts 'Done!'
  else
    puts 'Ok, bub.'
  end
rescue StandardError => error
  # If there's any error just drop the gun.
  puts error.to_s.red
  exit
end

