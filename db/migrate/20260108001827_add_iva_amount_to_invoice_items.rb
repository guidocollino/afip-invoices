class AddIvaAmountToInvoiceItems < ActiveRecord::Migration[6.1]
  def change
    add_column :invoice_items, :iva_amount, :float, default: 0.0
  end
end
