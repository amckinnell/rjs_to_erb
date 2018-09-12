module RjsToErb
  module Handlers
    class PageHandler
      include Unparser::NodeHelpers

      attr_reader :node, :rewriter

      def initialize(rewriter, node)
        @rewriter = rewriter
        @node = node
      end
    end
  end
end
