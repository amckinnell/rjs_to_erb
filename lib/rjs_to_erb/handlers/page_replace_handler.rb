module RjsToErb
  module Handlers
    class PageReplaceHandler < RjsToErb::Handlers::PageHandler
      def handle
        raise RjsToErb::MustTranslateManually unless args.size == 2

        content = case args[1].type
        when :hash
          <<~ERB.chomp
            <%= #{method_call}(#{[dom_id, partial, locals].compact.join(", ")}) %>
          ERB
        else
          <<~ERB.chomp
            <%= page_replace_html_with_html(#{dom_id}, #{html_content}) %>
          ERB
        end

        replace_range = node.location.expression
        rewriter.replace(replace_range, content)
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

      def html_content
        Unparser.unparse(args[1])
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

      def method_name
        node.to_a[1]
      end

      def args
        node.to_a[2..-1]
      end
    end
  end
end
