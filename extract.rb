#!/usr/bin/env ruby

require 'colorize'
require 'highline/import'
require 'open3'
require 'fileutils'
require 'pdf-reader'

require 'progress_bar'
# class Array
#   include ProgressBar::WithProgress
# end

require 'open3'

def extract_ocr(filename:, pageset:)
  content = []
  puts "Performing OCR on pages #{pageset}...".blue
  bar = ProgressBar.new pageset.count, :bar, :counter, :eta
  bar.increment! 0
  pageset.each do |page_number|
    stdout, _threads = Open3.pipeline_r(
      "convert -density 300 #{filename}[#{page_number}] "\
        '-background white -flatten +matte png:-',
      'tesseract stdin stdout'
    )
    content[page_number] = stdout.read.gsub(/\n+/, "\n")
    stdout.close
    bar.increment!
  end
  content
end

def extract_txt(filename:, pageset:)
  content = []
  puts "Extracting plain text from pages #{pageset}...".blue
  bar = ProgressBar.new pageset.count, :bar, :counter, :eta
  bar.increment! 0
  pageset.each do |page_number|
    stdout, _stderr, status = Open3.capture3(
      "pdftotext -f #{page_number} -l #{page_number} #{filename}"
    )
    error_message = "There was an error parsing page #{page_number+1} of the PDF, bub."
    raise error_message unless status.success?
    content[page_number] = stdout.gsub(/\n+/, "\n")
    bar.increment!
  end
  content
end
