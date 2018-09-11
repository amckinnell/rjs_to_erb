RSpec.describe RjsToErb::PageRewriter do
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
        $('factory_unit_uom_ratio_id').value = '<%= default_uom_ratio.id -%>';
      EXPECTED_ERB
    end

    xit "identifier with interpolation" do
      rjs_source = <<~'RJS'
        page << "$('planned_receipt_item_\#{@planned_receipt_item_id}_expiry_date').hide();"
      RJS

      erb = rewrite(rjs_source)

      expect(erb).to eq(<<~'EXPECTED_ERB')
        $('planned_receipt_item_<@= @planned_receipt_item_id -%>_expiry_date').hide();
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
        $('factory_unit_uom_ratio_id').value = '<%= default_uom_ratio.id -%>';
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

      erb = rewrite(rjs_source, "./modules/ip_whitelisting/app/views/ip_white_list_entries/create.js.rjs")

      expect(erb).to eq(<<~'EXPECTED_ERB')
        <%= page_replace(:ip_white_list_entry, partial: "new") %>
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

  context "ruby logic" do
    it "fails to rewrite if" do
      rjs_source = <<~'RJS'
        if @customer
          page << "$('shipment_outbound_trailer_bill_to').setValue('#{j @customer.name}')"
          page << "$('shipment_outbound_trailer_bill_to_address').setValue('#{j @customer.billing_address}')"
        end
      RJS

      expect { rewrite(rjs_source) }.to raise_error(RjsToErb::MustTranslateManually)
    end

    it "fails to rewrite unless" do
      rjs_source = <<~'RJS'
        unless @planned_receipt_item.sku.track_expiry_date?
          page << "$('planned_receipt_item_expiry_date').hide()"
          page << "$('planned_receipt_item_expiry_date').clear()"
        end
      RJS

      expect { rewrite(rjs_source) }.to raise_error(RjsToErb::MustTranslateManually)
    end

    it "fails to rewrite each" do
      rjs_source = <<~'RJS'
        @pallet_shipments.each do |ps|
          page.replace(table_row_id(ps), :partial => 'pallet_shipments/show')
        end
      RJS

      expect { rewrite(rjs_source) }.to raise_error(RjsToErb::MustTranslateManually)
    end
  end

  context "odds and sods" do
    it "unknown failure" do
      rjs_source = <<~'RJS'
        page.replace table_row_id(@pallet_shipment), :partial => "pallet_shipments/edit", :locals => { :pallet_shipment => @pallet_shipment }

        page << "$$('.data-row.highlight').invoke('removeClassName', 'highlight');"
      RJS

      erb = rewrite(rjs_source, "./modules/shipping/app/views/pallet_shipments/edit.js.rjs")

      expect(erb).to eq(<<~'EXPECTED_ERB')
        <%= page_replace(table_row_id(@pallet_shipment), partial: "edit", locals: { pallet_shipment: @pallet_shipment }) %>

        $$('.data-row.highlight').invoke('removeClassName', 'highlight');
      EXPECTED_ERB
    end
  end

  context "ruby logic" do
    xit "rewrites ruby logic" do
      rjs_source = <<~RJS
        unless @sku.track_expiry_date?
          page << "$('planned_receipt_item_expiry_date').hide()"
          page << "$('planned_receipt_item_expiry_date').clear()"
        end
      RJS

      erb = rewriter.rewrite_rjs(rjs_source)

      expected_erb = <<~ERB.chomp
        <% unless @sku.track_expiry_date? %>
          $('planned_receipt_item_expiry_date').hide()
          $('planned_receipt_item_expiry_date').clear()
        <% end %>
      ERB

      expect(erb).to eq(expected_erb)
    end

    xit "rewrites complex ruby logic" do
      rjs_source = <<~RJS
        if @jobs.empty?
          page.replace_html 'job_replace', ''
        else
          page.replace_html 'job_replace', :partial => 'choose_job', :locals => { :move => @move, :jobs => @jobs }
        end

        page << "$j('#attributes-div').hide();$j('#from_pallet_number').val('');"

        if @line && @jobs.empty?
          page << "$j('#new-move-form').show()"
        else
          page << "$j('#new-move-form').hide();"
        end
      RJS

      erb = rewriter.rewrite_rjs(rjs_source)

      expected_erb = <<~ERB.chomp
        <% if @jobs.empty? %>
          <%= page.replace_html_with_html(:job_replace, "") %>
        <% else %>
          <%= page.replace_html(:job_replace, partial: "choose_job", locals: { move: @move, jobs: @jobs }) %>
        <% end %>

        $j('#attributes-div').hide();$j('#from_pallet_number').val('');

        <% if @line && @jobs.empty? %>
          $j('#new-move-form').show()
        <% else %>
          $j('#new-move-form').hide();
        <% end %>
      ERB

      expect(erb).to eq(expected_erb)
    end
  end

  def rewrite(rjs_source, filename = "_dont_care_")
    buffer = create_buffer(rjs_source)

    parser = Parser::CurrentRuby.new
    ast = parser.parse(buffer)

    RjsToErb::PageRewriter.new(filename).rewrite(buffer, ast)
  end

  def create_buffer(rjs_source)
    Parser::Source::Buffer.new("_dont_care_").tap do |buffer|
      buffer.source = rjs_source
    end
  end
end
