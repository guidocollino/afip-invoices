# frozen_string_literal: true

class Invoice
  class AmountInWords
    UNITS = %w[
      cero uno dos tres cuatro cinco seis siete ocho nueve
      diez once doce trece catorce quince dieciséis diecisiete dieciocho diecinueve
      veinte veintiuno veintidós veintitrés veinticuatro veinticinco veintiséis veintisiete veintiocho veintinueve
    ].freeze

    TENS = %w[
      _ _ _ treinta cuarenta cincuenta sesenta setenta ochenta noventa
    ].freeze

    HUNDREDS = %w[
      _ ciento doscientos trescientos cuatrocientos quinientos seiscientos setecientos ochocientos novecientos
    ].freeze

    def initialize(amount)
      @amount = amount.round(2)
    end

    def call
      integer_part = @amount.to_i
      decimal_part = ((@amount - integer_part) * 100).round

      result = "Son pesos #{integer_to_words(integer_part)}"

      if decimal_part > 0
        centavo_word = decimal_part == 1 ? 'centavo' : 'centavos'
        decimal_text = integer_to_words(decimal_part)
        decimal_text = 'un' if decimal_part == 1
        result += " con #{decimal_text} #{centavo_word}"
      end

      result
    end

    private

    def integer_to_words(number)
      return 'cero' if number.zero?

      chunks = []

      if number >= 1_000_000
        millions = number / 1_000_000
        number %= 1_000_000
        chunks << if millions == 1
                    'un millón'
                  else
                    "#{below_thousand(millions)} millones"
                  end
      end

      if number >= 1000
        thousands = number / 1000
        number %= 1000
        chunks << if thousands == 1
                    'un mil'
                  else
                    "#{below_thousand(thousands)} mil"
                  end
      end

      chunks << below_thousand(number) if number > 0

      chunks.join(' ')
    end

    def below_thousand(number)
      return UNITS[number] if number < 30
      return 'cien' if number == 100

      parts = []

      if number >= 100
        parts << HUNDREDS[number / 100]
        number %= 100
      end

      if number >= 30
        parts << TENS[number / 10]
        remainder = number % 10
        parts[-1] = "#{parts[-1]} y #{UNITS[remainder]}" if remainder > 0
      elsif number > 0
        parts << UNITS[number]
      end

      parts.join(' ')
    end
  end
end
