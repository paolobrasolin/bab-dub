module BabDub
  class Job
    attr_reader :state

    def initialize(source_path)
      @source_path = source_path
      @state = :idle
    end

    def run
      case @state
      when :idle
        check_file
      when :loaded
        @state = :wants_method
      when :wants_method
        ask_method
      when :wants_extraction_ranges
        ask_extraction_ranges
      when :wants_target_path
        ask_target_path
      when :wants_extracted_text
        extract_text
      when :wants_lines
        extract_lines
        show_extracted_lines
        ask_meaningful_lines
        @state = :wants_lines_action
      when :wants_lines_action
        ask_line_action
      when :wants_lines
        ask_meaningful_lines
      when :wants_lines_operation
        show_meaningful_lines_content
        ask_lines_operation
      when :skipped
        puts "File skipped!".red
        return
      when :renamed
        puts "File renamed!".green
        return
      else
        puts @state
        raise "Unknown status, bub."
      end
      run
    end

    def check_file
      if File.file? @source_path and ['.pdf'].include? File.extname(@source_path)
        @state = :loaded
      else
        @state = :errored
      end
    end

    def ask_method
      _, choice = BabDub::Prompts::Prompt.new(
           question: "You can (s)kip, (m)anually rename, and try (o)cr or (d)irect text extraction. What do? ".blue,
           lead: 'd',
           regexp: /^[smod]$/i
         ).ask
      case choice
      when 's'
        @state = :skipped
      when 'm'
        @state = :wants_target_path
      when 'o'
        @extraction_technique = :ocr
        @state = :wants_extraction_ranges
      when 'd'
        @extraction_technique = :raw
        @state = :wants_extraction_ranges
      end
    end

    def ask_extraction_ranges
      @extraction_ranges, @extraction_ranges_parsed = BabDub::Prompts::QualifiedRanges.new(
        question: "Input extraction ranges: ".blue,
        lead: @extraction_ranges || '0[0..9]'
      ).ask
      @state = :wants_extracted_text
    end

    def extraction_pages
      page_set = []
      @extraction_ranges_parsed.each { |s| page_set.concat s[:pages].to_a }
      page_set.sort.uniq
    end

    def extract_text
      case @extraction_technique
      when :raw
        @extracted_text = extract_txt filename: @source_path, pageset: extraction_pages
      when :ocr
        @extracted_text = extract_ocr filename: @source_path, pageset: extraction_pages
      end

      if @extracted_text.join.gsub(/[[:space:]]/, '').empty?
        puts "No text found! Try changing method.".red
        @state = :wants_method
      else
        puts "Text extraction was successful.".green
        @state = :wants_lines
      end
    end

    def extract_lines
      @extracted_lines = []
      @extraction_ranges_parsed.each do |spec|
        @extracted_text[spec[:pages]].each do |page|
          @extracted_lines.concat page.lines[spec[:lines]]
        end
      end
    end

    def show_extracted_lines
      @extracted_lines.each_with_index do |line, index|
        line_number = index.to_s.rjust((@extracted_lines.length-1).to_s.length)
        puts "#{line_number}: ".green + line.rstrip.blue
      end
    end

    def ask_line_action
      _, choice = BabDub::Prompts::Prompt.new(
           question: "You can either (s)kip the file, (m)anually rename, choose some (l)ines or retry the (e)xtraction. What do? ".blue,
           lead: 'd',
           regexp: /^[smle]$/i
         ).ask
      case choice
      when 's'
        @state = :skipped
      when 'm'
        @state = :wants_lines_operation
      when 'l'
        @state = :wants_lines
      when 'e'
        @state = :wants_method
      end
    end

    def ask_meaningful_lines
      @meaningful_lines, meaningful_lines_parsed = BabDub::Prompts::UnqualifiedRanges.new(
        question: "Select some meaningful lines: ".blue,
        lead: @meaningful_lines || '0..1'
      ).ask

      @meaningful_lines_content = []
      meaningful_lines_parsed.each do |range|
        @meaningful_lines_content << @extracted_lines[range]
      end

      puts @meaningful_lines_content

      @state = :wants_lines_operation
    end

    def show_meaningful_lines_content
      puts @meaningful_lines_content
      @state = :wants_lines_operation
    end

    def ask_lines_operation
      _, choice = BabDub::Prompts::Prompt.new(
           question: "You can either (s)kip the file, (r)ename it, (q)uery Google Scholar or choose some (l)ines. What do? ".blue,
           lead: 'd',
           regexp: /^[srql]$/i
         ).ask
      case choice
      when 's'
        @state = :skipped
      when 'r'
        @state = :wants_target_path
      when 'q'
        @state = :wants_query
      when 'l'
        @state = :wants_lines
      end
    end

    def ask_target_path
      dirname = BabDub::Options.get[:output_folder] || File.dirname(@source_path)
      basename = @suggested_name || File.basename(@source_path)
      @target_path = BabDub::Prompts::Prompt.new(
        question: 'Choose the new file path: '.blue,
        lead: File.join(dirname, basename),
        regexp: //
      ).ask

      # FileUtils.mkdir_p File.dirname(@target_path)
      # File.rename @source_path, @target_path
      @state = :renamed
    end

  end
end
