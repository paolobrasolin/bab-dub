require 'optparse'

module BabDub
  module Options
    @@options = {}

    def self.get
      @@options
    end

    def self.parse
      OptionParser.parse!
      set_defaults
      # NOTE: order matters; after OptionParser.parse! only globs are left in ARGV.
      @@options[:input_files] = parse_globs ARGV
    end

    private

    OptionParser = OptionParser.new do |opt|
      opt.banner = "Usage: bab-dub [OPTIONS] FILES"
      opt.separator  ""
      opt.separator  "Options"

      opt.on "-n", "--name=FORMAT", "name format for file renaming (default: %title_%AUTHORS.%extension)" do |name_format|
        @@options[:name_format] = name_format
      end

      opt.on "-o", "--output-to=PATH", "renamed files folder (default: null, renames in place)" do |output_folder|
        @@options[:output_folder] = File.realpath output_folder
      end

      opt.on "-r", "--reject-to=PATH", "rejected files folder (default: null, leaves in place)" do |reject_folder|
        @@options[:reject_folder] = File.realpath reject_folder
      end

      opt.on "-d", "--dry-run", "perform a dry run" do
        @@options[:dry_run] = true
      end

      opt.on "-v", "--verbose", "show verbose (debug) output" do
        @@options[:verbose] = true
      end

      opt.on "-h", "--help", "help" do
        puts option_parser
      end
    end

    def self.set_defaults
      @@options[:name_format] ||= '%title_%AUTHORS.%extension'
    end

    def self.parse_globs(globs)
      globs
        .map { |f| Dir.glob f }
        .flatten
        .map { |f| File.realpath f }
        .uniq
    end
  end
end
