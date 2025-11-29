class AddRecipientIvaTypeIdToInvoices < ActiveRecord::Migration[6.1]
  def change
    add_column :invoices, :recipient_iva_type_id, :integer
  end
end
