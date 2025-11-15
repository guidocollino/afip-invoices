# frozen_string_literal: true

module V1
  class InvoicesController < ApplicationController
    skip_before_action :authenticate, only: [:export, :test_preview]
    before_action :fetch_invoice, only: %i[show export]

    ITEM_PARAMS = %i[
      quantity
      unit_price
      description
      bonus_percentage
      code
      metric_unit
      iva_aliquot_id
    ].freeze

    ASSOCIATED_INVOICE_PARAMS = %i[
      bill_type_id sale_point_id number date cuit rejected
    ].freeze

    IVA_PARAMS = %i[
      id net_amount total_amount
    ].freeze

    TAX_PARAMS = %i[
      id description net_amount rate total_amount
    ].freeze

    INVOICE_PARAMS = [
      :sale_point_id, :concept_type_id, :recipient_type_id, :recipient_iva_type_id,
      :recipient_number, :net_amount, :iva_amount, :untaxed_amount,
      :exempt_amount, :tax_amount, :bill_type_id, :created_at,
      :total_amount, :service_from, :service_to, :due_date, :note,
      :cbu, :alias, :transmission, :receipt_comercial_address, :sale_condition,
      {
        associated_invoices: [ASSOCIATED_INVOICE_PARAMS],
        taxes: [TAX_PARAMS],
        iva: [IVA_PARAMS],
        items: [ITEM_PARAMS],
      }
    ].freeze

    CREATION_RESULT_STATUS = {
      created: :created,
      existing: :ok,
      in_progress: :continue,
    }.freeze

    def index
      render json: entity.invoices
    end

    def show
      if @invoice
        render json: Invoice::Finder.new(
          invoice: @invoice,
          entity: entity,
        ).run
      else
        render_not_found
      end
    end

    def create
      generation = Invoice::Generator.new(invoice_params, entity, invoice_client_identifier).call

      if generation.with_errors?
        render json: {
          afip_errors: generation.afip_errors,
          errors: generation.errors,
        }, status: :bad_request
      else
        render json: generation.represented_invoice,
          status: CREATION_RESULT_STATUS[generation.status]
      end
    end

    def details
      invoice = Invoice::Finder.new(
        params: invoice_details_params,
        entity: entity,
      ).run

      if invoice
        render json: invoice
      else
        render_not_found
      end
    end

    def export
      if @invoice
        copy_type = params[:copy_type]&.to_sym || :original
        respond_to do |format|
          format.pdf { send_pdf(@invoice, nil, copy_type) }
        end
      else
        render_not_found
      end
    end

    def export_preview
      invoice = Invoice::Builder.new(invoice_preview_params, @entity).call

      respond_to do |format|
        format.pdf { send_pdf(invoice, invoice_preview_params) }
      end
    end

    def test_preview
      generator = Invoice::TestDataGenerator.new(
        items_count: params[:items_count] || 5,
        bill_type_id: params[:bill_type_id],
        has_taxes: params[:has_taxes] == 'true',
        has_associated_invoices: params[:has_associated_invoices] == 'true',
        copy_type: params[:copy_type]&.to_sym || :original,
        recipient_type: params[:recipient_type]&.to_sym || :company
      )

      test_data = generator.call

      invoice = build_test_invoice(test_data, generator)

      begin
        respond_to do |format|
          format.pdf { send_test_pdf(invoice, test_data, params[:copy_type]&.to_sym || :original) }
        end
      rescue StandardError => e
        puts "ERROR: #{e.class} - #{e.message}"
        puts "BACKTRACE:"
        puts e.backtrace.first(20).join("\n")
        raise
      end
    end

    private

    def invoice_params
      params.permit(*INVOICE_PARAMS)
    end

    def invoice_preview_params
      params.permit(:bill_number, *INVOICE_PARAMS)
    end

    def invoice_details_params
      params.permit(:bill_number, :sale_point_id, :bill_type_id)
    end

    def invoice_client_identifier
      params.permit(:external_id)
    end

    def send_pdf(invoice, invoice_data = nil, copy_type = :original)
      invoice_data = Invoice::DataFormatter.new(invoice_data).call if invoice_data

      if copy_type == :duplicate || copy_type == :triplicate
        send_data InvoicePdf.generate_combined_copies(invoice, invoice_data, copy_type),
          filename: 'factura_completa.pdf',
          type: 'application/pdf',
          disposition: 'inline'
      else
        send_data InvoicePdf.new(invoice, invoice_data, copy_type).render,
          filename: 'factura.pdf',
          type: 'application/pdf',
          disposition: 'inline'
      end
    end

    def send_test_pdf(invoice, invoice_data, copy_type = :original)
      invoice_data = Invoice::DataFormatter.new(invoice_data).call

      send_data TestInvoicePdf.new(invoice, invoice_data, copy_type).render,
        filename: 'factura_test.pdf',
        type: 'application/pdf',
        disposition: 'inline'
    end

    def fetch_invoice
      @invoice = Invoice.find_by(token: params[:id])
    end

    def build_test_invoice(test_data, generator)
      params_copy = test_data.dup
      params_copy.delete(:recipient_number)

      entity = Entity.new(
        cuit: '20-1234567', # dummy CUIT
        business_name: 'Ferretería Platense Scabuzzo e hijos SRL',
        comertial_address: '490 1900- La Plata Noreste Calle 80, Buenos Aires',
        condition_against_iva: 'No aplica',
        iibb: '1234567890',
        activity_start_date: Date.today,
        logo: File.open(Rails.root.join('app/pdfs/logo_test.png')),
      )

      invoice = Invoice.new(
        entity: entity,
        emission_date: test_data[:created_at],
        authorization_code: "111111111111",
        receipt: "#{format('%0004d', test_data[:sale_point_id])}-#{format('%008d', test_data[:bill_number])}",
        bill_type_id: test_data[:bill_type_id],
        logo_url: entity.logo.to_s,
        note: test_data[:note],
        cbu: test_data[:cbu],
        alias: test_data[:alias],
        receipt_comercial_address: test_data[:receipt_comercial_address],
        sale_condition: test_data[:sale_condition],
      )

      invoice.recipient = generator.generate_recipient_data

      test_data[:items]&.each do |item|
        invoice.items.build(
          code: item[:code],
          description: item[:description],
          unit_price: item[:unit_price],
          quantity: item[:quantity] || 1,
          bonus_percentage: item[:bonus_percentage] || 0,
          metric_unit: item[:metric_unit] || Invoice::Creator::DEFAULT_ITEM_UNIT,
          iva_aliquot_id: item[:iva_aliquot_id],
        )
      end

      test_data[:associated_invoices]&.each do |item|
        invoice.associated_invoices.build(
          invoice: invoice,
          bill_type_id: item[:bill_type_id],
          emission_date: item[:date],
          receipt: "#{item[:sale_point_id]}-#{item[:number]}",
        )
      end

      define_test_qr_code(invoice, test_data)

      invoice
    end

    def define_test_qr_code(invoice, test_data)
      invoice.define_singleton_method(:qr_code) do
        {
          'ver' => test_data[:concept_type_id].to_i,
          'fecha' => emission_date.strftime('%Y-%m-%d'),
          'cuit' => entity.cuit.to_i,
          'ptoVta' => test_data[:sale_point_id].to_i,
          'tipoCmp' => bill_type_id,
          'nroCmp' => test_data[:bill_number].to_i,
          'importe' => test_data[:total_amount].to_f,
          'moneda' => 'PES',
          'ctz' => 1.0,
          'tipoDocRec' => test_data[:recipient_type_id].to_i,
          'nroDocRec' => test_data[:recipient_number].to_i,
          'tipoCodAut' => 'E',
          'codAut' => authorization_code.to_i,
        }.to_json
      end
    end
  end
end
