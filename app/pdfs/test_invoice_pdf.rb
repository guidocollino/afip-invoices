require_relative '../pdfs/invoice_pdf'

class TestInvoicePdf < InvoicePdf
  def initialize(invoice, invoice_data = nil, copy_type = :original)
    @invoice        = invoice
    @entity         = invoice.entity
    @invoice_finder = invoice_data
    @taxes          = @invoice_finder[:taxes]
    @iva            = @invoice_finder[:iva]
    @copy_type      = copy_type

    mock_resources = Invoice::StaticResourceMock.new(@entity)
    @bill_type      = mock_resources.bill_types.find(invoice.bill_type_id)
    @iva_types      = mock_resources.iva_types
    @tax_types      = mock_resources.tax_types

    @items = invoice.items

    Prawn::Document.instance_method(:initialize).bind(self).call(top_margin: 70)

    repeat :all do
      display_copy_type_header
      display_header
      display_footer if @invoice.authorization_code?
    end

    repeat :all, dynamic: true do
      bounding_box [245, 60], width: bounds.width do
        number_pages 'Pág. <page>/<total>'
      end
    end

    display_items_and_totals
  end
end
