module RjsToErb
  module Handlers
    class PageShovelHandler < RjsToErb::Handlers::PageHandler
      def handle
        content = case args.type
        when :str
          args.to_a.first
        when :dstr
          args.to_a.map do |arg|
            case arg.type
            when :str
              arg.to_a.first
            else
              "<%= #{Unparser.unparse(arg.to_a.first)} %>"
            end
          end.join
        else
          raise RjsToErb::MustTranslateManually
        end

        replace_range = node.location.expression
        rewriter.replace(replace_range, content)
      end

      private

      def args
        node.to_a[2..-1].first
      end
    end
  end
end
