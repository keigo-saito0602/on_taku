class CreateArtists < ActiveRecord::Migration[8.1]
  def change
    create_table :artists do |t|
      t.string :name, null: false
      t.string :genre
      t.string :official_link
      t.integer :kind, null: false, default: 0
      t.boolean :published, null: false, default: true

      t.timestamps
    end
    add_index :artists, :name, unique: true
  end
end
