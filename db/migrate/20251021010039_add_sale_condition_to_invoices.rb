class AddSaleConditionToInvoices < ActiveRecord::Migration[6.1]
  def change
    add_column :invoices, :sale_condition, :string
  end
end
