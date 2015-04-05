ActiveRecord::Schema.define do
  create_table :sketch_files do |t|
    t.string :dropbox_path
    t.string :dropbox_rev
    t.datetime :last_modified
    t.boolean :in_sync, default: 0, null: false
    t.string :tag_cache
  end

  create_table :taggings do |t|
    t.string :type, null: false
    t.integer :weight, null: false
    t.string :dropbox_path, null: false
  end

  execute <<-SQL.strip
    CREATE VIRTUAL TABLE slices USING fts4(
      sketch_file_id INTEGER NOT NULL,
      path VARCHAR(256) NOT NULL,
      layer VARCHAR(256) NOT NULL,
      tokenize=simple
    );
SQL
end
