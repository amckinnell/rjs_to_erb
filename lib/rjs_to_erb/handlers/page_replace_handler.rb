module RjsToErb
  module Handlers
    class PageReplaceHandler < RjsToErb::Handlers::PageHandler
      attr_reader :args, :method_name, :rjs_filename

      def initialize(rjs_filename, node)
        @rjs_filename = rjs_filename

        _receiver_node, method_name, *args = *node

        @method_name = method_name
        @args = args
      end

      def handle
        raise RjsToErb::MustTranslateManually unless args.size == 2

        <<~ERB.chomp
          <%= #{method_call}(#{[dom_id, partial, locals].compact.join(", ")}) %>
        ERB
      end

      private

      def dom_id
        dom_identifier = args[0]

        case dom_identifier.type
        when :dstr
          "\"#{dom_identifier.to_a.first.to_a.last}\#{#{Unparser.unparse(dom_identifier.to_a.last)}}\""
        when :send
          Unparser.unparse(dom_identifier)
        when :str
          if dom_identifier.to_a.last =~ /^\w+$/
            Unparser.unparse(s(:sym, dom_identifier.to_a.last.to_sym))
          else
            Unparser.unparse(s(:str, dom_identifier.to_a.last))
          end
        when :sym
          Unparser.unparse(s(:sym, dom_identifier.to_a.last))
        else
          raise RjsToErb::MustTranslateManually
        end
      end

      def locals
        args[1].to_a[1].to_a.empty? ? nil : "locals: #{Unparser.unparse(args[1].to_a[1].to_a.last)}"
      end

      def method_call
        Unparser.unparse(s(:send, nil, "page_#{method_name}".to_sym))
      end

      def partial
        "partial: \"#{args[1].to_a[0].to_a.last.to_a.last}\""
      end
    end
  end
end
