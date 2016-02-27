class CreateRegistrations < ActiveRecord::Migration
  def up
    create_table :registrations do |t|
      t.references :poster, null: false
      t.integer  "status", default: 0, null: false
      t.string   "client_ip", null: false
      t.datetime "purchased_at"
      t.string   "receipt_id"
      t.string   "full_name"
      t.string   "organization"
      t.string   "email"
      t.string   "phone"
      t.timestamps
    end

    add_index "registrations", ["poster_id"], name: "index_registrations_on_poster_id"
  end

  def down
    drop_table :registrations
  end
end
