class CreatePaymentTransactions < ActiveRecord::Migration
  def up
    create_table :payment_transactions do |t|
      t.references :registration, null: false
      t.string   "status", length: 40, null: false
      t.string   "uuid", null: false
      t.decimal  "gross_amount", precision: 10, scale: 2, default: 0.0, null: false
      t.string   "currency_code", null: false
      t.string   "transaction_id"
      t.text     "notification_params"

      t.timestamps
    end
  end

  def down
    drop_table :payment_transactions
  end
end
