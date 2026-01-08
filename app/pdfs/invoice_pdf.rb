require 'prawn/qrcode'

class InvoicePdf < ToPdf
  MINIMUN_POSITION_TO_DISPLAY_NOTE = 130
  MINIMUN_POSITION_TO_DISPLAY_TOTALS = 300

  FINAL_CONSUMER_ID = '99'

  WIDTH = 540
  TOP = 725

  URL = 'https://www.afip.gob.ar/fe/qr/'

  def initialize(invoice, invoice_data = nil, copy_type = :original)
    super(top_margin: 70)
    @invoice        = invoice
    @entity         = invoice.entity
    @invoice_finder = invoice_data || Invoice::Finder.new(entity: @entity, invoice: @invoice).run
    @taxes          = @invoice_finder[:taxes]
    @iva            = @invoice_finder[:iva]
    @bill_type      = StaticResource::BillTypes.new(@entity).find(invoice.bill_type_id)
    @bill_type      = bill_type(invoice.bill_type_id)
    @iva_types      = StaticResource::IvaTypes.new(@entity)
    @tax_types      = StaticResource::TaxTypes.new(@entity)
    @copy_type      = copy_type

    @items = invoice.items
    @items = @items.order(:id) if invoice.persisted?

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

  private

  def display_copy_type_header
    bounding_box([0, TOP], width: WIDTH, height: 30) do
      text copy_type_label,
           align: :center,
           style: :bold,
           size: 14,
           valign: :center

      stroke_bounds
    end
  end

  def display_header
    header_top = TOP - 35
    
    stroke_rectangle [0, header_top], WIDTH, 160
    stroke_rectangle [0, 590 - 35], WIDTH, 25

    bounding_box([WIDTH / 2 - 25, header_top], width: 50, height: 50) do
      text_box(
        StaticResource::BillTypes::SHORT_NAMES[@bill_type.to_sym] || @bill_type,
        at: [1, cursor - 10],
        style: :bold,
        align: :center,
        size: 22,
        width: 48,
        height: 50,
        overflow: :shrink_to_fit,
        disable_wrap_by_char: true,
      )

      move_down 40

      text "COD. #{@invoice.bill_type_id.to_s.rjust(2, '0')}",
        align: :center, style: :bold, size: 7

      stroke_bounds
    end

    bounding_box([0, header_top], width: 250, height: 50) do
      if @invoice.logo_url.present?
        image uploaded_file_path(@invoice.logo_url),
          fit: [200, 45],
          position: :center,
          vposition: :center
      else
        text @entity.business_name, size: 12, style: :bold, align: :center, valign: :center
      end
    end

    bounding_box([320, header_top], width: 220, height: 70) do
      text_box(
        bill_type_name,
        at: [0, cursor - 15],
        style: :bold,
        align: :left,
        size: 18,
        width: 200,
        height: 20,
        overflow: :shrink_to_fit,
        disable_wrap_by_char: true,
      )

      move_down 40

      text_box "Punto de Venta: <font size='9'>#{@invoice_finder[:sale_point_id]}</font>",
        at: [0, cursor],
        style: :bold,
        inline_format: true,
        size: 8

      text_box "Comp. Nro: <font size='9'>#{@invoice_finder[:bill_number]}</font>",
        at: [110, cursor],
        style: :bold,
        inline_format: true,
        size: 8

      move_down 15

      text_box "Fecha de Emisión: <font size='9'>#{@invoice.emission_date.strftime('%d/%m/%Y')}</font>",
        at: [0, cursor],
        style: :bold,
        inline_format: true,
        size: 8
    end

    bounding_box([10, 650 - 15], width: 250, height: 70) do
      field 'Razón social', @entity.business_name
    end

    bounding_box([10, 635 - 35], width: 250, height: 50) do
      field 'Domicilio comercial', @entity.comertial_address
    end

    bounding_box([10, 605 - 35], width: 250, height: 50) do
      text "Condición frente al IVA: #{@entity.condition_against_iva}", style: :bold
    end

    bounding_box([320, 650 - 35], width: 250, height: 50) do
      field 'C.U.I.T.', @entity.cuit
    end

    bounding_box([320, 630 - 35], width: 250, height: 50) do
      field 'Ingresos Brutos', @entity.iibb
    end

    bounding_box([320, 610 - 35], width: 250, height: 50) do
      field 'Fecha de Inicio de Actividades', @entity.activity_start_date.try(:strftime, '%d/%m/%Y')
    end

    bounding_box([10, 580 - 35], width: 490, height: 50) do
    end

    bounding_box([220, 580 - 35], width: 490, height: 50) do
    end

    if @invoice_finder[:due_date]
      bounding_box([340, 580 - 35], width: 490, height: 50) do
        field 'Fecha de Vto. para el pago', @invoice_finder[:due_date]
      end
    end

    if invoice_is_fce?
      stroke_rectangle [0, 560 - 35], WIDTH, 25

      bounding_box([10, 550 - 35], width: 490, height: 50) do
        field 'CBU', @invoice.cbu
      end

      bounding_box([220, 550 - 35], width: 490, height: 50) do
        field 'ALIAS', @invoice.alias || '--'
      end
    end

    bounding_box([0, cursor + 30], width: 540, height: 60) do
      c = cursor
      bounding_box([10, c], width: 560, height: 70) do
        move_down 10
        field 'CUIT', @invoice_finder[:recipient_number], size: 7
        field 'Ape. y Nom. / Razón Social', recipient[:name].upcase, size: 7
        field 'Domicilio', @invoice.receipt_comercial_address.presence || recipient[:full_address], size: 7
      end

      bounding_box([360, c], width: 170, height: 60) do
        move_down 10
        field 'Condición frente al IVA', @invoice.recipient_iva_type, size: 7
        move_down 10
        field 'Condición de Venta', @invoice.sale_condition, size: 7

        display_associated_invoices
      end

      stroke_bounds
    end

    stroke do
      vertical_line 590 - 35, header_top - 50, at: WIDTH / 2
    end

    move_down 20
  end

  def display_associated_invoices
    return unless @invoice.associated_invoices.present?

    items = @invoice.associated_invoices.map do |invoice|
      "#{invoice.sale_point_id.to_s.rjust(4, '0')}-#{invoice.bill_number.to_s.rjust(8, '0')}"
    end

    field 'Remito', items.join(', '), size: 7
  end

  def display_items_and_totals
    stretchy_cursor = invoice_is_fce? ? 460 - 35 : 480 - 35

    bounding_box([0, stretchy_cursor], width: 540, height: 330) do
      display_items

      display_note if @invoice.note.present?

      display_totals
    end
  end

  def display_items
    data = [
      [
        'Cód.',
        'Producto/Servicio',
        'Cant.',
        'Uni. Med.',
        'Precio Unit.',
        '% Bonif.',
        'Subtotal'
      ],
    ]

    @items.each do |item|
      item_price = item.unit_price + item.iva_amount
      item_subtotal =
        item.quantity * item_price * ((100 - item.bonus_percentage) / 100)

      data.insert(-1, [
        item.code,
        item.description,
        item.quantity,
        item.metric_unit,
        number_with_precision(item_price, precision: 2),
        number_with_precision(item.bonus_percentage, precision: 2),
        number_with_precision(item_subtotal, precision: 2)
      ])
    end

    table_params = {
      width: 540,
      cell_style: { size: 7 },
      column_widths: { 1 => 150 },
    }

    table(data, table_params) do
      cells.borders              = []
      row(0).font_style          = :bold
      row(0).background_color    = 'E3DDDC'
      column(0..1).align         = :left
      row(0).columns(2..8).align = :center
      columns(2..8).align        = :right
    end
  end

  def display_note
    if y < MINIMUN_POSITION_TO_DISPLAY_NOTE
      start_new_page
    else
      move_down 12
    end

    bounding_box([35, cursor], width: 370) do
      formatted_text [
        {
          text: "Nota: #{@invoice.note}",
          size: 7,
          styles: %i[bold italic],
        },
      ]
    end
  end

  def display_totals
    start_new_page if y < MINIMUN_POSITION_TO_DISPLAY_TOTALS

    footer_starts_in = invoice_is_fce? ? 90 : 87

    stroke_rectangle [0, footer_starts_in + 10], 540, 100
    data = [['Descripción', 'Alic.%', 'Importe']]

    if @taxes.present?
      @taxes.each do |t|
        description = @tax_types.find t[:id]
        data.insert(-1, [description, t[:rate], t[:total_amount]])
      end
    end

    bounding_box([10, footer_starts_in], width: 155, height: 90) do
      text 'Otros Tributos', style: :bold, size: 8
      table(data, width: 150, cell_style: { size: 5 }) do
        cells.borders = [:bottom]
        row(0).font_style = :bold
        row(0).background_color = 'E3DDDC'
        column(-1).align = :right
      end
      move_down 10
      text "Importe Otros Tributos: $ #{@invoice_finder[:tax_amount]}",
        align: :right,
        size: 6
    end

    bounding_box([160, footer_starts_in], width: 145, height: 90) do
      data_iva = []

      if @iva.present?
        @iva.each do |iva|
          name = @iva_types.find iva[:id]
          data_iva.insert(-1, [
            "IVA #{name}: $",
            number_with_precision(iva[:total_amount], precision: 2),
          ])
        end
      end

      table_params = {
        width: 140,
        cell_style: {
          align: :right,
          padding: 0,
          size: 9,
          font_style: :bold,
        },
      }

      table(data_iva, table_params) do
        cells.borders = []
      end
    end

    bounding_box([315, footer_starts_in], width: 200, height: 90) do
      data_iva = []

      data_iva.insert(-1, [
        'Subtotal: $',
        number_with_precision(@invoice_finder[:total_amount], precision: 2),
      ])

      data_iva.insert(-1, [
        'Importe Otros Tributos: $',
        number_with_precision(@invoice_finder[:tax_amount], precision: 2),
      ])

      data_iva.insert(-1, [
        'Importe Total: $',
        number_with_precision(@invoice_finder[:total_amount], precision: 2),
      ])

      table_params = {
        width: 195,
        cell_style: {
          align: :right,
          padding: 0,
          size: 9,
          font_style: :bold,
        },
      }

      table(data_iva, table_params) do
        cells.borders = []
        row(-1).size = 11
        row(0..-1).height = 15
      end
    end
  end

  def display_footer
    bounding_box([0, 75], width: 150, height: 65) do
      encoded_data = Base64.strict_encode64(@invoice.qr_code)
      qr_code_content = "#{URL}?p=#{encoded_data}"
      qr_code = RQRCode::QRCode.new(qr_code_content)

      render_qr_code(qr_code, stroke: false, dot: 1)
    end

    bounding_box [bounds.left, 75], height: 40, width: bounds.width do
      if @invoice_finder[:emission_type] == 'CAE'
        paragraph "CAE N°: #{@invoice_finder[:authorization_code]}", align: :right, style: :bold
        paragraph "Fecha de Vto. de CAE: #{@invoice_finder[:expiracy_date]}", align: :right, style: :bold
      end
    end
  end

  def recipient
    return @recipient if @recipient.present?
    @invoice.recipient = final_consumer_recipient if @invoice_finder[:recipient_type_id] == FINAL_CONSUMER_ID

    Invoice::RecipientLoader.new(@invoice).call(@invoice_finder[:recipient_number]) if @invoice.recipient.blank?

    @recipient = @invoice.recipient

    if @recipient.nil? && !Rails.env.production?
      @recipient = {
        name: 'Unagi',
        zipcode: '1900',
        address: '48 1488 3D',
        state: 'Buenos Aires',
        city: 'La Plata',
        category: 'Responsable Inscripto',
        full_address: '48 1488 3D La Plata, Buenos Aires',
      }
    end

    @recipient.symbolize_keys!
  end

  # El nombre del tipo de comprobante se recibe como
  # "Nota de Débito A"/"Nota de Crédito B"/"Recibo C"
  # Se trunca la letra del tipo de comprobante
  def bill_type_name
    result = @bill_type.sub(/\s+[A-Z]$/, '').mb_chars.upcase.to_s

    return 'RECIBO' if result == 'RECIBOS'

    result
  end

  def invoice_is_fce?
    @invoice.fce?
  end

  def invoice_is_note?
    @invoice.note?
  end

  def bill_type(bill_type_id)
    StaticResource::BillTypes.new(@entity).find(bill_type_id)
  end

  def final_consumer_recipient
    {
      name: '',
      zipcode: '',
      address: '',
      state: '',
      city: '',
      category: 'Consumidor Final',
      full_address: '',
    }
  end

  def copy_type_label
    case @copy_type
    when :original
      'ORIGINAL'
    when :duplicate
      'DUPLICADO'
    when :triplicate
      'TRIPLICADO'
    else
      'ORIGINAL'
    end
  end

  def self.generate_copy(invoice, copy_type, invoice_data = nil)
    new(invoice, invoice_data, copy_type).render
  end

  def self.generate_combined_copies(invoice, invoice_data = nil, copy_type = :duplicate)
    require 'combine_pdf'

    copies_to_include = case copy_type
                       when :duplicate
                         [:original, :duplicate]
                       when :triplicate
                         [:original, :duplicate, :triplicate]
                       else
                         [:original]
                       end

    combined_pdf = CombinePDF.new

    copies_to_include.each do |copy|
      copy_pdf_data = generate_copy(invoice, copy, invoice_data)
      pdf = CombinePDF.parse(copy_pdf_data)
      combined_pdf << pdf
    end

    combined_pdf.to_pdf
  end
end
