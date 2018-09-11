module RjsToErb
  module Handlers
    class PageShovelHandler < RjsToErb::Handlers::PageHandler
      attr_reader :args

      def initialize(_rjs_filename, node)
        _receiver_node, _method_name, *args = *node

        raise RjsToErb::MustTranslateManually unless args.size == 1

        @args = args.first
      end

      def handle
        case args.type
        when :str
          args.children.first
        when :dstr
          args.children.map do |arg|
            case arg.type
            when :str
              arg.children.first
            else
              "<%= #{Unparser.unparse(arg.children.first)} %>"
            end
          end.join
        else
          raise RjsToErb::MustTranslateManually
        end
      end
    end
  end
end
