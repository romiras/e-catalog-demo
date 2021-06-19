class CreateDocuments < ActiveRecord::Migration
  def up
    create_table :documents do |t|
      t.belongs_to :poster
      t.string     "filename"
    end
  end
  def down
    drop_table :documents
  end
end
