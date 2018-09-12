module RjsToErb
  class Rewriter
    attr_reader :rjs_filename, :rjs_source

    def self.rewrite_rjs(rjs_source)
      new(rjs_source).rewrite_rjs
    end

    def initialize(rjs_source)
      @rjs_source = rjs_source
    end

    def rewrite_rjs
      rewrite_to_erb = RjsRewriter.new
      rewrite_to_erb.rewrite(buffer, ast)
    end

    private

    def ast
      parser = Parser::CurrentRuby.new

      parser.parse(buffer)
    end

    def buffer
      @buffer ||= Parser::Source::Buffer.new("_dont_care_").tap do |buffer|
        buffer.source = rjs_source
      end
    end
  end
end
