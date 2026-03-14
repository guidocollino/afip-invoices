# frozen_string_literal: true

require 'test_helper'

RSpec.describe Invoice::AmountInWords do
  subject { described_class.new(amount).call }

  context 'with whole numbers' do
    let(:amount) { 4_755_012.00 }

    it { is_expected.to eq 'Son pesos cuatro millones setecientos cincuenta y cinco mil doce' }
  end

  context 'with centavos' do
    let(:amount) { 1500.50 }

    it { is_expected.to eq 'Son pesos un mil quinientos con cincuenta centavos' }
  end

  context 'with zero pesos and centavos' do
    let(:amount) { 0.99 }

    it { is_expected.to eq 'Son pesos cero con noventa y nueve centavos' }
  end

  context 'with one centavo' do
    let(:amount) { 3000.01 }

    it { is_expected.to eq 'Son pesos tres mil con un centavo' }
  end

  context 'with zero' do
    let(:amount) { 0.00 }

    it { is_expected.to eq 'Son pesos cero' }
  end

  context 'with one million' do
    let(:amount) { 1_000_000.00 }

    it { is_expected.to eq 'Son pesos un millón' }
  end

  context 'with exact hundred' do
    let(:amount) { 100.00 }

    it { is_expected.to eq 'Son pesos cien' }
  end

  context 'with hundreds and units' do
    let(:amount) { 521.00 }

    it { is_expected.to eq 'Son pesos quinientos veintiuno' }
  end

  context 'with tens requiring y' do
    let(:amount) { 45.00 }

    it { is_expected.to eq 'Son pesos cuarenta y cinco' }
  end

  context 'with exact thousand' do
    let(:amount) { 1000.00 }

    it { is_expected.to eq 'Son pesos un mil' }
  end
end
