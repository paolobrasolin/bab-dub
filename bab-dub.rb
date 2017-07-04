#!/usr/bin/env ruby

require_relative 'lib/options'
BabDub::Options.parse

require_relative 'lib/prompt'






# require 'highline/import'
require 'open3'
require 'fileutils'
require 'progress_bar'
# class Array
#   include ProgressBar::WithProgress
# end
require 'open3'
require "i18n"
I18n.config.available_locales = :en
require_relative 'lib/extract'
require 'tempfile'








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

  ranges = BabDub::RangesPrompt.new(
    question: question.blue,
    lead: lead
  ).ask

  apply_range_list(ranges: ranges, iterable: lines)
end

# This will be obsolete
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





require_relative 'lib/job.rb'


begin

  filename = check_filename ARGV[0]

  job = BabDub::Job.new filename
  job.run



  # header = q_lines.join

  # # Prepare search string from matched header.
  # search_string = header.gsub(/\s+/, ' ').strip
  # search_string = I18n.transliterate search_string
  # search_string = BabDub::Prompt.new(
  #   question: 'Confirm search string: '.blue,
  #   lead: search_string,
  #   regexp: //
  # ).ask

  # # Use scholar.py to fetch the best (first) match.
  # result, stderr, status = Open3.capture3(
  #   'python2.7',
  #   'scholar.py/scholar.py',
  #   '--citation=en',
  #   '-c 1',
  #   "--all=\"#{search_string}\""
  # )
  # raise stderr unless status.success?
  # query_result = result.strip

  # if query_result.empty?
  #   puts "No result!".red
  #   should_rename_file = BabDub::BoolPrompt.new(
  #     question: "Wanna rename the file manually? ".blue,
  #     lead: 'n'
  #   ).ask

  #   if should_rename_file
  #     tmp_file = Tempfile.new('bab-dub-')
  #     begin
  #       tmp_file.write search_string
  #       tmp_file.flush
  #       system "vi #{tmp_file.path}"
  #       tmp_file.rewind
  #       safe_filename = tmp_file.read.strip
  #     ensure
  #       tmp_file.close
  #       tmp_file.unlink
  #     end
  #   end
  # else
  #   puts "Best Google Scholar result:\n  " + query_result

  #   # Extract and format title.
  #   title = I18n.transliterate result.scan(/%T (.*)/).first.first
  #   safe_title = title.downcase.gsub(/[^A-Za-z0-9 ]/, ' ').strip.gsub(/\s+/, '_')

  #   # Extract and format authors.
  #   authors = result.scan(/%A (.*),/).map(&:first).map { |a| I18n.transliterate a }
  #   safe_authors = authors.uniq.join('_').upcase.gsub(/\s+/, '_')

  #   # Format new filename.
  #   puts safe_authors
  #   puts safe_title
  #   safe_filename = "#{safe_title}_#{safe_authors}.pdf"
  #   puts "Proposed filename:\n  " + safe_filename

  #   # Ask wheter to rename file.
  #   should_rename_file = BabDub::BoolPrompt.new(
  #     question: "Wanna rename the file? ".blue,
  #     lead: 'y'
  #   ).ask
  # end

  # # Conditionally rename file.
  # if should_rename_file
  #   dirname = File.dirname filename
  #   FileUtils.mkdir_p File.join(dirname, 'dubbed')
  #   File.rename filename, File.join(dirname, 'dubbed', new_filename)
  #   puts 'Done!'
  # else
  #   puts 'Ok, bub.'
  # end
rescue StandardError => error
  # If there's any error just drop the gun.
  puts error.to_s.red
  exit
end

