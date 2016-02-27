class CreatePosters < ActiveRecord::Migration
  def up
    create_table :posters do |t|
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :name, null: false
      t.string :sku, null: false

      t.timestamps
    end
  end

  def down
    drop_table :posters
  end
end
