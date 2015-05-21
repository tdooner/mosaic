ActiveRecord::Schema.define do
  create_table :mosaic_files do |t|
    t.string :type
    t.string :dropbox_path
    t.string :dropbox_rev
    t.datetime :last_modified
    t.boolean :in_sync, default: 0, null: false
    t.string :tag_cache
  end

  create_table :sketch_pages do |t|
    t.string :bounds
    t.string :name
  end

  create_table :sketch_artboards do |t|
    t.references :sketch_page
    t.string :bounds
    t.string :name

    t.index :sketch_page_id
  end

  create_table :taggings do |t|
    t.string :type, null: false
    t.integer :weight, null: false
    t.string :dropbox_path, null: false
  end

  execute <<-SQL.strip
    CREATE VIRTUAL TABLE pages_fts USING fts4(
      page_id INTEGER NOT NULL,
      body TEXT NOT NULL,
      tokenize=simple
    );
    CREATE VIRTUAL TABLE slices_fts USING fts4(
      slice_id INTEGER NOT NULL,
      body TEXT NOT NULL,
      tokenize=simple
    );
SQL
end
