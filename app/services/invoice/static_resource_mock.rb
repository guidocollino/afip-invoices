class Invoice
  class StaticResourceMock
    def initialize(entity)
      @entity = entity
    end

    def bill_types
      MockBillTypes.new(@entity)
    end

    def iva_types
      MockIvaTypes.new(@entity)
    end

    def tax_types
      MockTaxTypes.new(@entity)
    end

    class MockBillTypes
      def initialize(entity)
        @entity = entity
      end

      def find(id)
        TYPES[id.to_s] || "Factura"
      end

      TYPES = {
        '1' => 'Factura A',
        '2' => 'Nota de Débito A',
        '3' => 'Nota de Crédito A',
        '6' => 'Factura B',
        '7' => 'Nota de Débito B',
        '8' => 'Nota de Crédito B',
        '11' => 'Factura C',
        '12' => 'Nota de Débito C',
        '13' => 'Nota de Crédito C',
        '15' => 'Recibos A',
        '16' => 'Recibos B',
        '17' => 'Recibo C',
        '201' => 'Factura de Crédito electrónica MiPyMEs (FCE) A',
        '202' => 'Nota de Crédito electrónica MiPyMEs (FCE) A',
        '203' => 'Nota de Débito electrónica MiPyMEs (FCE) A',
        '206' => 'Factura de Crédito electrónica MiPyMEs (FCE) B',
        '207' => 'Nota de Crédito electrónica MiPyMEs (FCE) B',
        '208' => 'Nota de Débito electrónica MiPyMEs (FCE) B',
        '211' => 'Factura de Crédito electrónica MiPyMEs (FCE) C',
        '212' => 'Nota de Crédito electrónica MiPyMEs (FCE) C',
        '213' => 'Nota de Débito electrónica MiPyMEs (FCE) C',
      }.freeze
    end

    class MockIvaTypes
      def initialize(entity)
        @entity = entity
      end

      def find(id)
        TYPES[id.to_i] || "IVA 21%"
      end

      TYPES = {
        3 => '0%',
        4 => '10,5%',
        5 => '21%',
        6 => '27%',
        98 => 'Exento',
        99 => 'No gravado',
      }.freeze
    end

    class MockTaxTypes
      def initialize(entity)
        @entity = entity
      end

      def find(id)
        "Impuesto #{id}"
      end
    end
  end
end
