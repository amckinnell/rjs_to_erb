module RjsToErb
  class Runner
    def initialize(filenames)
      @filenames = filenames
      @conversions = []
    end

    def execute
      @filenames.each do |filename|
        @current_filename = filename

        rewrite_current if rjs_template?
      end

      display_conversions
    end

    private

    attr_reader :current_filename

    def display_conversions
      return if @conversions.empty?

      puts
      puts @conversions.join("\n")
    end

    def rewrite_current
      with_error_handling do
        rewritten_erb = rjs_rewritten_as_erb

        git_move_rjs_file
        File.write(erb_filename, rewritten_erb)

        @conversions << <<~MSG.chomp
          Success #{current_filename} -> #{File.basename(erb_filename)}
        MSG
      end
    end

    def git_move_rjs_file
      cmd = "git mv '#{current_filename}' '#{erb_filename}'"

      system(cmd)
    end

    def erb_filename
      current_filename.gsub(/rjs$/, "erb")
    end

    def rjs_rewritten_as_erb
      rjs_source = File.read(current_filename)

      RjsToErb::Rewriter.rewrite_rjs(rjs_source)
    end

    def rjs_template?
      File.extname(current_filename) == ".rjs"
    end

    def with_error_handling
      yield
    rescue RjsToErb::MustTranslateManually
      @conversions << <<~MSG.chomp
        Failure #{current_filename}. Manual translation required.
      MSG
    rescue => e
      @conversions << <<~MSG.chomp
        Failure #{current_filename}. Error: #{e.message}
      MSG
    end
  end
end
