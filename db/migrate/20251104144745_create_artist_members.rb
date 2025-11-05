class CreateArtistMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :artist_members do |t|
      t.references :artist, null: false, foreign_key: true
      t.string :name, null: false
      t.string :instrument
      t.string :role
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :artist_members, [ :artist_id, :position ]
  end
end
