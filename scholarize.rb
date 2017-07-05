#!/usr/bin/env ruby
# coding: utf-8

require 'colorize'
require 'open3'

require "i18n"
I18n.config.available_locales = :en

require_relative 'lib/prompt'

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

puts "\nRemember, bub: when prompted ENTER to confirm, CTRL-U + ENTER to skip.".green

BabDub::Options.get[:input_files].each do |source_path|
  puts "\n"

  puts qm.yellow + ' ' + source_path

  query_string = sanitize_file_path source_path
  _, chosen_query = BabDub::Prompts::Prompt.new(
       question: "Proposed query:\n  ".cyan,
       lead: query_string,
       regexp: //
     ).ask

  if chosen_query.empty?
    puts ko.red + ' File skipped, bub.'
  else
    query_result = query_scholar chosen_query

    # This exception should never raise in normal use cases:
    raise query_result[:stderr] unless query_result[:exit_code].success?

    if !query_result[:stdout].empty? # not an infallible check, but hey ¯\_(ツ)_/¯
      puts "Query result:".cyan
      puts query_result[:stdout].strip.gsub(/^%./) { |m| "  " + m.cyan }
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

      _, chosen_path = BabDub::Prompts::Prompt.new(
          question: "Proposed filename:\n  ".cyan,
          lead: target_path,
          regexp: //
        ).ask

      if chosen_path.empty?
        puts ko.red + ' File skipped, bub.'
      else
        File.rename source_path, target_path unless BabDub::Options.get[:dry_run]
        puts ok.green + ' ' + target_path
      end
    else
      puts "No results, bub.".red
      target_dirname = BabDub::Options.get[:reject_folder] || File.dirname(source_path)
      target_basename = File.basename(source_path)
      target_path = File.join target_dirname, target_basename

      _, chosen_path = BabDub::Prompts::Prompt.new(
          question: "Proposed filename:\n  ".cyan,
          lead: target_path,
          regexp: //
        ).ask

      if chosen_path.empty?
        puts ko.red + ' File skipped, bub.'
      else
        File.rename source_path, target_path unless BabDub::Options.get[:dry_run]
        puts ok.red + ' ' + target_path
      end
    end
  end
end

puts "\n"
