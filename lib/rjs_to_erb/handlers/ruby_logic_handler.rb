module RjsToErb
  module Handlers
    class RubyLogicHandler < RjsToErb::Handlers::PageHandler
      def handle
        condition_node, *args = node.to_a

        keyword = case node.location.keyword.size
        when 2
          "if"
        when 6
          "unless"
        else
          raise RjsToErb::MustTranslateManually
        end

        if_unless_range = node.location.keyword.join(condition_node.location.expression)
        rewriter.replace(if_unless_range, "<% #{keyword} #{Unparser.unparse(condition_node)} %>")

        rewriter.process(args[0])

        else_range = node.location.else
        rewriter.replace(else_range, "<% else %>") unless else_range.nil?

        rewriter.process(args[1])

        end_range = node.location.end
        rewriter.replace(end_range, "<% end %>")
      end
    end
  end
end
