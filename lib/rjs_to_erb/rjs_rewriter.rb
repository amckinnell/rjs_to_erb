module RjsToErb
  class RjsRewriter < Parser::TreeRewriter
    include Unparser::NodeHelpers

    def on_if(node)
      handle_ruby_logic(node)
    end

    def on_send(node)
      if node_is_each?(node)
        handle_each
      elsif node_is_page?(node)
        handle_page(node)
      else
        raise RjsToErb::MustTranslateManually
      end
    end

    private

    def node_is_page?(node)
      node.to_a[0].to_a.last == :page
    end

    def node_is_each?(node)
      node.to_a.last == :each
    end

    def handle_each
      raise RjsToErb::MustTranslateManually
    end

    def handle_page(node)
      method_name = node.to_a[1]

      case method_name
      when :replace, :replace_html
        handle_page_replace(node)
      when :<<
        handle_page_shovel(node)
      else
        raise RjsToErb::MustTranslateManually
      end
    end

    def handle_ruby_logic(node)
      RjsToErb::Handlers::RubyLogicHandler.new(self, node).handle
    end

    def handle_page_replace(node)
      RjsToErb::Handlers::PageReplaceHandler.new(self, node).handle
    end

    def handle_page_shovel(node)
      RjsToErb::Handlers::PageShovelHandler.new(self, node).handle
    end
  end
end
