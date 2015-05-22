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
    t.references :sketch_file, null: false
    t.string :uuid
    t.string :bounds
    t.string :name

    t.index :uuid
    t.index :sketch_file_id
  end

  create_table :sketch_artboards do |t|
    t.references :sketch_page, null: false
    t.string :uuid
    t.string :bounds
    t.string :name

    t.index :sketch_page_id
    t.index :uuid
  end

  execute <<-SQL.strip
    CREATE VIRTUAL TABLE pages_fts USING fts4(
      page_id INTEGER NOT NULL,
      body TEXT NOT NULL,
      tokenize=simple
    );
  SQL
  execute <<-SQL.strip
    CREATE VIRTUAL TABLE artboards_fts USING fts4(
      artboard_id INTEGER NOT NULL,
      body TEXT NOT NULL,
      tokenize=simple
    );
SQL
end
