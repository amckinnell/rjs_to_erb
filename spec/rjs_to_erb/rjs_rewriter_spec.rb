RSpec.describe RjsToErb::RjsRewriter do
  context "page <<" do
    it "simple method" do
      rjs_source = <<~'RJS'
        page << "$('factory_unit_quantity').hide;"
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        $('factory_unit_quantity').hide;
      EXPECTED_ERB
    end

    it "simple assignment" do
      rjs_source = <<~'RJS'
        page << "$('factory_unit_quantity').value = '';"
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        $('factory_unit_quantity').value = '';
      EXPECTED_ERB
    end

    it "assignment with interpolation" do
      rjs_source = <<~'RJS'
        page << "$('factory_unit_uom_ratio_id').value = '#{default_uom_ratio.id}';"
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        $('factory_unit_uom_ratio_id').value = '<%= default_uom_ratio.id %>';
      EXPECTED_ERB
    end

    it "identifier with interpolation" do
      rjs_source = <<~'RJS'
        page << "$('planned_receipt_item_#{@planned_receipt_item_id}_expiry_date').hide();"
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        $('planned_receipt_item_<%= @planned_receipt_item_id %>_expiry_date').hide();
      EXPECTED_ERB
    end

    it "multiple expressions" do
      rjs_source = <<~'RJS'
        page << "$('factory_unit_quantity').value = '';"
        page << "$('factory_unit_uom_ratio_id').value = '#{default_uom_ratio.id}';"
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        $('factory_unit_quantity').value = '';
        $('factory_unit_uom_ratio_id').value = '<%= default_uom_ratio.id %>';
      EXPECTED_ERB
    end
  end

  context "page.replace" do
    it "simple replacement" do
      rjs_source = <<~'RJS'
        page.replace "bookmark_details", :partial => "edit", locals: { bookmark: @bookmark }
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        <%= page_replace(:bookmark_details, partial: "edit", locals: { bookmark: @bookmark }) %>
      EXPECTED_ERB
    end

    it "identifier is a string (and not a symbol)" do
      rjs_source = <<~'RJS'
        page.replace "bookmark-details", partial: "edit", locals: { bookmark: @bookmark }
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        <%= page_replace("bookmark-details", partial: "edit", locals: { bookmark: @bookmark }) %>
      EXPECTED_ERB
    end

    it "identifier with interpolation" do
      rjs_source = <<~'RJS'
        page.replace "list_#{@list.id}", :partial => 'lists/show', :locals => {:list => @list}
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        <%= page_replace("list_#{@list.id}", partial: "lists/show", locals: { list: @list }) %>
      EXPECTED_ERB
    end

    it "multiline rjs" do
      rjs_source = <<~'RJS'
        page.replace(
          :ip_white_list_entry,
          :partial => "ip_white_list_entries/new"
        )
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        <%= page_replace(:ip_white_list_entry, partial: "ip_white_list_entries/new") %>
      EXPECTED_ERB
    end
  end

  context "page.replace_html" do
    it "rewrites" do
      rjs_source = <<~'RJS'
        page.replace_html("invoice_item_#{invoice_item.id}", :partial => "edit", :locals => {invoice: invoice, invoice_item: invoice_item})
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        <%= page_replace_html("invoice_item_#{invoice_item.id}", partial: "edit", locals: { invoice: invoice, invoice_item: invoice_item }) %>
      EXPECTED_ERB
    end
  end

  context "page.replace_html_with_html" do
    it "rewrites" do
      rjs_source = <<~'RJS'
        if @site.global_access?
          page.replace_html "ip_white_list_entries_section", ""
        else
          page.replace_html "ip_white_list_entries_section", :partial => "ip_white_list_entries/index"
        end
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        <% if @site.global_access? %>
          <%= page_replace_html_with_html(:ip_white_list_entries_section, "") %>
        <% else %>
          <%= page_replace_html(:ip_white_list_entries_section, partial: "ip_white_list_entries/index") %>
        <% end %>
      EXPECTED_ERB
    end

    it "rewrites with expression" do
      rjs_source = <<~'RJS'
        page.replace_html("success-message", @success_message)
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        <%= page_replace_html_with_html("success-message", @success_message) %>
      EXPECTED_ERB
    end
  end

  context "fails for ruby logic" do
    it "fails to rewrite each" do
      rjs_source = <<~'RJS'
        @pallet_shipments.each do |ps|
          page.replace(table_row_id(ps), :partial => 'pallet_shipments/show')
        end
      RJS

      expect { rewrite(rjs_source) }.to raise_error(RjsToErb::MustTranslateManually)
    end
  end

  context "ruby logic" do
    it "rewrites if" do
      rjs_source = <<~'RJS'
        if @customer
          page << "$('shipment_outbound_trailer_bill_to').setValue('#{j @customer.name}')"
          page << "$('shipment_outbound_trailer_bill_to_address').setValue('#{j @customer.billing_address}')"
        end
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        <% if @customer %>
          $('shipment_outbound_trailer_bill_to').setValue('<%= j(@customer.name) %>')
          $('shipment_outbound_trailer_bill_to_address').setValue('<%= j(@customer.billing_address) %>')
        <% end %>
      EXPECTED_ERB
    end

    it "rewrites if with else" do
      rjs_source = <<~'RJS'
        if @customer
          page << "$('shipment_outbound_trailer_bill_to').setValue('#{j @customer.name}')"
          page << "$('shipment_outbound_trailer_bill_to_address').setValue('#{j @customer.billing_address}')"
        else
          page << "$('shipment_outbound_trailer_bill_to').setValue('')"
          page << "$('shipment_outbound_trailer_bill_to_address').setValue('')"
        end
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        <% if @customer %>
          $('shipment_outbound_trailer_bill_to').setValue('<%= j(@customer.name) %>')
          $('shipment_outbound_trailer_bill_to_address').setValue('<%= j(@customer.billing_address) %>')
        <% else %>
          $('shipment_outbound_trailer_bill_to').setValue('')
          $('shipment_outbound_trailer_bill_to_address').setValue('')
        <% end %>
      EXPECTED_ERB
    end

    it "rewrites unless" do
      rjs_source = <<~'RJS'
        unless @sku.track_expiry_date?
          page << "$('planned_receipt_item_#{@planned_receipt_item_id}_expiry_date').hide()"
          page << "$('planned_receipt_item_#{@planned_receipt_item_id}_expiry_date').clear()"
        end
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        <% unless @sku.track_expiry_date? %>
          $('planned_receipt_item_<%= @planned_receipt_item_id %>_expiry_date').hide()
          $('planned_receipt_item_<%= @planned_receipt_item_id %>_expiry_date').clear()
        <% end %>
      EXPECTED_ERB
    end

    it "complex" do
      rjs_source = <<~'RJS'
        unless @receipt_item.receipt.received?
          if @receipt_item.sku && !@receipt_item.sku.track_expiry_date?
            page << "if ($('receipt_item_#{@receipt_item.id}_expiry_date')) $('receipt_item_#{@receipt_item.id}_expiry_date').hide()"
            page << "if ($('receipt_item_#{@receipt_item.id}_expiry_date')) $('receipt_item_#{@receipt_item.id}_expiry_date').clear()"
          end
  
          if @receipt_item.sku && !@receipt_item.sku.track_lot_code?
            page << "if ($('receipt_item_#{@receipt_item.id}_expiry_date')) $('receipt_item_#{@receipt_item.id}_lot_code').hide()"
            page << "if ($('receipt_item_#{@receipt_item.id}_expiry_date')) $('receipt_item_#{@receipt_item.id}_lot_code').clear()"
          end
        end
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        <% unless @receipt_item.receipt.received? %>
          <% if @receipt_item.sku && (!@receipt_item.sku.track_expiry_date?) %>
            if ($('receipt_item_<%= @receipt_item.id %>_expiry_date')) $('receipt_item_<%= @receipt_item.id %>_expiry_date').hide()
            if ($('receipt_item_<%= @receipt_item.id %>_expiry_date')) $('receipt_item_<%= @receipt_item.id %>_expiry_date').clear()
          <% end %>
  
          <% if @receipt_item.sku && (!@receipt_item.sku.track_lot_code?) %>
            if ($('receipt_item_<%= @receipt_item.id %>_expiry_date')) $('receipt_item_<%= @receipt_item.id %>_lot_code').hide()
            if ($('receipt_item_<%= @receipt_item.id %>_expiry_date')) $('receipt_item_<%= @receipt_item.id %>_lot_code').clear()
          <% end %>
        <% end %>
      EXPECTED_ERB
    end
  end

  context "odds and sods" do
    it "unknown failure" do
      rjs_source = <<~'RJS'
        page.replace table_row_id(@pallet_shipment), :partial => "pallet_shipments/edit", :locals => { :pallet_shipment => @pallet_shipment }

        page << "$$('.data-row.highlight').invoke('removeClassName', 'highlight');"
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        <%= page_replace(table_row_id(@pallet_shipment), partial: "pallet_shipments/edit", locals: { pallet_shipment: @pallet_shipment }) %>

        $$('.data-row.highlight').invoke('removeClassName', 'highlight');
      EXPECTED_ERB
    end
  end

  def rewrite(rjs_source)
    buffer = create_buffer(rjs_source)

    parser = Parser::CurrentRuby.new
    ast = parser.parse(buffer)

    RjsToErb::RjsRewriter.new.rewrite(buffer, ast)
  end

  def create_buffer(rjs_source)
    Parser::Source::Buffer.new("_dont_care_").tap do |buffer|
      buffer.source = rjs_source
    end
  end
end
