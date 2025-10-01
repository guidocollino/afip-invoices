class AddReceiptComercialAddressToInvoices < ActiveRecord::Migration[6.1]
  def change
    add_column :invoices, :receipt_comercial_address, :string
  end
end
