class AddSaleConditionDetailAndPurchaseOrderToInvoices < ActiveRecord::Migration[6.1]
  def change
    add_column :invoices, :sale_condition_detail, :string
    add_column :invoices, :purchase_order, :string
  end
end
