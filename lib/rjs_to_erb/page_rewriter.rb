module RjsToErb
  class PageRewriter < Parser::TreeRewriter
    include Unparser::NodeHelpers

    attr_reader :rjs_filename

    def initialize(rjs_filename)
      @rjs_filename = rjs_filename
    end

    def on_if(*)
      raise RjsToErb::MustTranslateManually
    end

    def on_unless(*)
      raise RjsToErb::MustTranslateManually
    end

    def on_send(node)
      receiver_node, method_name, = *node

      raise RjsToErb::MustTranslateManually unless receiver_node == s(:send, nil, :page)

      content = case method_name
      when :replace, :replace_html
        handle_page_replace(node)
      when :<<
        handle_page_shovel(node)
      else
        raise RjsToErb::MustTranslateManually
      end

      replace_range = node.location.expression
      replace(replace_range, content)
    end

    private

    def handle_page_replace(node)
      RjsToErb::Handlers::PageReplaceHandler.new(rjs_filename, node).handle
    end

    def handle_page_shovel(node)
      RjsToErb::Handlers::PageShovelHandler.new(rjs_filename, node).handle
    end
  end
end
