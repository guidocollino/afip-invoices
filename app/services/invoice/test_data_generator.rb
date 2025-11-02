class Invoice
  class TestDataGenerator
    PRODUCT_NAMES = [
      'Tornillo hexagonal 8x50mm',
      'Pintura látex interior 10L',
      'Cemento Portland x 50kg',
      'Cable unipolar 2.5mm x metro',
      'Llave térmica 2x25A',
      'Caño PVC 110mm x 3mts',
      'Adhesivo para cerámicos x 30kg',
      'Llave mezcladora FV Pampa',
      'Disyuntor diferencial 2x40A',
      'Membrana asfáltica 4mm x 10m',
      'Ladrillo hueco 8x18x33',
      'Aislante térmico placa 50mm',
      'Varilla hierro construcción 8mm',
      'Sifón plástico universal',
      'Cinta aisladora vinílica',
    ].freeze

    METRIC_UNITS = ['Unidad', 'Metro', 'Kg', 'Litro', 'Metro cuadrado', 'Caja'].freeze

    RECIPIENT_NAMES = [
      'CONSTRUCTORA DEL SUR SA',
      'MATERIALES Y SERVICIOS SRL',
      'OBRAS Y PROYECTOS SA',
      'INSTALACIONES TECNICAS SRL',
      'COMERCIAL FERRETERA SA',
    ].freeze

    STREETS = [
      'Av. Corrientes', 'Calle Florida', 'Av. Rivadavia', 'Calle Lavalle',
      'Av. Belgrano', 'Calle Maipú', 'Av. Santa Fe', 'Calle Reconquista'
    ].freeze

    CITIES = [
      { name: 'Ciudad Autónoma de Buenos Aires', state: 'CABA' },
      { name: 'La Plata', state: 'Buenos Aires' },
      { name: 'Mar del Plata', state: 'Buenos Aires' },
      { name: 'Rosario', state: 'Santa Fe' },
      { name: 'Córdoba', state: 'Córdoba' },
    ].freeze

    SALE_CONDITIONS = ['Contado', 'Cuenta Corriente', '30 días', '60 días', 'Cheque'].freeze

    IVA_ALIQUOTS = [3, 4, 5, 6].freeze
    BILL_TYPES = ['1', '6', '11', '201', '206', '211'].freeze

    def initialize(
      items_count: 5,
      bill_type_id: nil,
      has_taxes: false,
      has_associated_invoices: false,
      copy_type: :original,
      recipient_type: :company
    )
      @items_count = [items_count.to_i, 1].max
      @bill_type_id = bill_type_id || BILL_TYPES.sample
      @has_taxes = has_taxes
      @has_associated_invoices = has_associated_invoices
      @copy_type = copy_type
      @recipient_type = recipient_type
    end

    def call
      items = generate_items
      iva_data = calculate_iva(items)
      taxes_data = @has_taxes ? generate_taxes : []

      net_amount = iva_data[:net_amount]
      untaxed_amount = iva_data[:untaxed_amount]
      exempt_amount = iva_data[:exempt_amount]
      iva_amount = iva_data[:iva_amount]
      tax_amount = taxes_data.sum { |t| t[:total_amount] }
      total_amount = net_amount + untaxed_amount + exempt_amount + iva_amount + tax_amount

      {
        sale_point_id: rand(1..9999),
        concept_type_id: 1,
        recipient_type_id: @recipient_type == :final_consumer ? 99 : 80,
        recipient_number: generate_cuit,
        recipient_iva_type_id: @recipient_type == :final_consumer ? 5 : 1,
        net_amount: net_amount.round(2),
        iva_amount: iva_amount.round(2),
        untaxed_amount: untaxed_amount.round(2),
        exempt_amount: exempt_amount.round(2),
        tax_amount: tax_amount.round(2),
        bill_type_id: @bill_type_id,
        created_at: Time.zone.now.strftime(Invoice::Schema::DATE_FORMAT),
        total_amount: total_amount.round(2),
        service_from: format_date(30.days.ago),
        service_to: format_date(Time.zone.now),
        due_date: format_date(30.days.from_now),
        note: rand < 0.3 ? generate_note : nil,
        cbu: is_fce? ? generate_cbu : nil,
        alias: is_fce? ? generate_alias : nil,
        receipt_comercial_address: @recipient_type == :final_consumer ? nil : generate_address,
        sale_condition: SALE_CONDITIONS.sample,
        associated_invoices: @has_associated_invoices ? generate_associated_invoices : [],
        taxes: taxes_data,
        iva: iva_data[:iva_details],
        items: items,
        bill_number: rand(1..99999999),
        emission_type: 'CAE',
        authorization_code: '111111111111',
        expiracy_date: format_date(Time.zone.now + 1.day),
      }
    end

    def generate_recipient_data
      if @recipient_type == :final_consumer
        {
          name: 'Consumidor Final',
          zipcode: '',
          address: '',
          state: '',
          city: '',
          category: 'Consumidor Final',
          full_address: '',
        }
      else
        city_data = CITIES.sample
        street = STREETS.sample
        number = rand(100..9999)

        {
          name: RECIPIENT_NAMES.sample,
          zipcode: rand(1000..9999).to_s,
          address: "#{street} #{number}",
          state: city_data[:state],
          city: city_data[:name],
          category: 'Responsable Inscripto',
          full_address: "#{street} #{number}, #{city_data[:name]}, #{city_data[:state]}",
        }
      end
    end

    private

    def generate_items
      @items_count.times.map do |i|
        {
          quantity: rand(1..100),
          unit_price: rand(100.0..10000.0).round(2),
          description: PRODUCT_NAMES.sample,
          bonus_percentage: [0, 0, 0, 5, 10, 15].sample,
          code: "PROD-#{format('%04d', i + 1)}",
          metric_unit: METRIC_UNITS.sample,
          iva_aliquot_id: IVA_ALIQUOTS.sample,
        }
      end
    end

    def calculate_iva(items)
      iva_groups = {}
      net_amount = 0.0
      untaxed_amount = 0.0
      exempt_amount = 0.0

      items.each do |item|
        item_total = item[:quantity] * item[:unit_price] * ((100 - item[:bonus_percentage]) / 100.0)
        aliquot_id = item[:iva_aliquot_id]

        if aliquot_id == StaticResource::IvaTypes::UNTAXED_ID
          untaxed_amount += item_total
        elsif aliquot_id == StaticResource::IvaTypes::EXEMPT_ID
          exempt_amount += item_total
        else
          net_amount += item_total
          iva_groups[aliquot_id] ||= { net_amount: 0.0, rate: get_iva_rate(aliquot_id) }
          iva_groups[aliquot_id][:net_amount] += item_total
        end
      end

      iva_details = iva_groups.map do |id, data|
        {
          id: id,
          net_amount: data[:net_amount].round(2),
          total_amount: (data[:net_amount] * data[:rate] / 100.0).round(2),
        }
      end

      iva_amount = iva_details.sum { |iva| iva[:total_amount] }

      {
        net_amount: net_amount,
        untaxed_amount: untaxed_amount,
        exempt_amount: exempt_amount,
        iva_amount: iva_amount,
        iva_details: iva_details,
      }
    end

    def generate_taxes
      rand(1..3).times.map do |i|
        net_amount = rand(1000.0..5000.0).round(2)
        rate = [2.5, 3.0, 3.5, 4.0].sample
        {
          id: i + 1,
          description: "Impuesto Municipal #{i + 1}",
          net_amount: net_amount,
          rate: rate,
          total_amount: (net_amount * rate / 100.0).round(2),
        }
      end
    end

    def generate_associated_invoices
      rand(1..3).times.map do
        {
          bill_type_id: '91',
          sale_point_id: rand(1..9999),
          number: rand(1..99999999),
          date: format_date(rand(1..30).days.ago),
          cuit: generate_cuit,
          rejected: false,
        }
      end
    end

    def generate_cuit
      if @recipient_type == :final_consumer
        rand(10_000_000..99_999_999).to_s
      else
        prefix = %w[20 23 27 30 33].sample
        middle = rand(10_000_000..99_999_999)
        "#{prefix}#{middle}#{rand(0..9)}"
      end
    end

    def generate_address
      street = STREETS.sample
      number = rand(100..9999)
      city_data = CITIES.sample
      "#{street} #{number}, #{city_data[:name]}, #{city_data[:state]}"
    end

    def generate_cbu
      "#{rand(1000..9999)}#{rand(1000..9999)}#{rand(100_000_000_000_000..999_999_999_999_999)}"
    end

    def generate_alias
      words = %w[FERRETERIA MATERIALES CONSTRUCCION OBRAS SERVICIOS PAGOS]
      "#{words.sample}.#{words.sample}.#{words.sample}"
    end

    def generate_note
      notes = [
        'Entrega en obra incluida. Horario: 8 a 17hs.',
        'Mercadería sujeta a disponibilidad de stock.',
        'Garantía de fábrica aplicable según términos del fabricante.',
        'Validez de la cotización: 15 días corridos.',
      ]
      notes.sample
    end

    def format_date(date)
      date.strftime(Invoice::Schema::DATE_FORMAT)
    end

    def is_fce?
      Invoice::Schema::ELECTRONIC_CREDIT_INVOICES_IDS.include?(@bill_type_id)
    end

    def get_iva_rate(aliquot_id)
      case aliquot_id
      when 3 then 0.0
      when 4 then 10.5
      when 5 then 21.0
      when 6 then 27.0
      else 21.0
      end
    end
  end
end
