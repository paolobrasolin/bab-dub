#!/usr/bin/env ruby

require 'colorize'
require 'open3'

require "i18n"
I18n.config.available_locales = :en

require_relative 'lib/options'
BabDub::Options.parse

def sanitize_file_path(path)
  I18n.transliterate(File.basename(path, '.*'))
    .gsub(/\([^()]*\)/, '') # drop parenthesized stuff
    .gsub(/[^a-z0-9]/i, ' ') # replace non alphanumeric characters
    .gsub(/\b[A-Z]\b/i, '') # drop single letter words
    .squeeze(' ').strip.downcase
end

def query_scholar(query_string)
  stdout, stderr, exit_code = Open3.capture3(
    %{python2.7 scholar.py/scholar.py --citation=en -c 1 --all="#{query_string}"})
  {
    title: stdout.scan(/%T (.*)\r/).map(&:first).first,
    authors: stdout.scan(/%A (.*),/).map(&:first),
    exit_code: exit_code,
    stderr: stderr,
    stdout: stdout
  }
end

# Cute dings.
ok = "\u2714"
ko = "\u2718"
qm = "\u272E"

BabDub::Options.get[:input_files].each do |source_path|
  puts "\n"
  puts qm.yellow + ' ' + source_path
  query_string = sanitize_file_path source_path
  query_result = query_scholar query_string

  # This exception should never raise in normal use cases:
  raise query_result[:stderr] unless query_result[:exit_code].success?

  if !query_result[:stdout].empty? # not an infallible check, but hey.
    safe_title = I18n.transliterate(query_result[:title])
                   .downcase.gsub(/[^a-z0-9 ]/i, ' ')
                   .strip.gsub(/\s+/, '_')
    safe_authors = query_result[:authors]
                     .map { |a| I18n.transliterate a }
                     .uniq.join('_')
                     .upcase.gsub(/\s+/, '_')
    target_dirname = BabDub::Options.get[:output_folder] || File.dirname(source_path)
    target_basename = [safe_title, '_', safe_authors, File.extname(source_path)].join
    target_path = File.join target_dirname, target_basename
    puts ok.green + ' ' + target_path
  else
    target_dirname = BabDub::Options.get[:reject_folder] || File.dirname(source_path)
    target_basename = File.basename(source_path)
    target_path = File.join target_dirname, target_basename
    puts ko.red + ' ' + target_path
  end

  File.rename source_path, target_path unless BabDub::Options.get[:dry_run]
end

puts "\n"
