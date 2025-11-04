class CreateArtistSocialLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :artist_social_links do |t|
      t.references :artist, null: false, foreign_key: true
      t.string :label, null: false, default: ""
      t.string :url, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :artist_social_links, [:artist_id, :position]
  end
end
