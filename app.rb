require 'active_record'
require 'haml'
require 'sinatra'
require 'sinatra/json'
require 'threaded'

require_relative 'lib/sketch_sync_dropbox'
require_relative 'models/slice'
require_relative 'models/sketch_file'

$logger = Logger.new(STDOUT)

# TODO: Fix this to only be images/
set :public_folder, '.'

def recreate_schema
  ActiveRecord::Schema.define do
    %w[sketch_files slices].each do |t|
      drop_table t if table_exists?(t)
    end

    create_table :sketch_files do |t|
      t.string :dropbox_path
      t.string :dropbox_rev
      t.boolean :in_sync, default: 0, null: false
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
end

def schema_exists?
  ActiveRecord::Base.connection.tables.include?('images')
end

def index_changes(changes)
  Slice.transaction do
    changes.each do |change|
      s = SketchFile.where(dropbox_path: change[:original_path]).first_or_create(dropbox_rev: change[:rev])
      Slice.where(
        sketch_file: s,
        path: change[:path],
        layer: change[:layer_tokens].join(' ')
      ).first_or_create
    end
  end
end

configure do
  ENV['DATABASE_URL'] ||= 'sqlite3:db/development.sqlite3'

  SketchSyncDropbox.authenticate!(ENV['DROPBOX_APP_KEY'], ENV['DROPBOX_APP_SECRET'])

  ActiveRecord::Base.logger = $logger
  ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
  ActiveRecord::Base.connection.tap(&:verify!)

  recreate_schema

  SketchFile.create(dropbox_path: '/design/snowflakes/jason/partner tools.sketch', dropbox_rev: 'abc')
  SketchFile.create(dropbox_path: '/design/snowflakes/jenn/product/style guide.sketch', dropbox_rev: 'abc')
  SketchFile.create(dropbox_path: '/design/snowflakes/kevin/User Position/[iOS] User Position.sketch', dropbox_rev: 'abc')
  # create_schema unless schema_exists?
  SketchFile.update_all(in_sync: false)

  Threaded.logger = $logger
  Threaded.inline = false
  Threaded.start

  SketchFile.sync_all

  # index_changes
end

get '/' do
  haml :index
end

post '/search' do
  results = Slice.find_by_search(params[:query]).includes(:sketch_file)

  json({
    search: [params[:query]],
    results: results.map { |r| { image_url: r.path, dropbox_url: r.sketch_file.dropbox_path, layer: r.layer } }
  })
end

get '/status' do
  json({
    files: SketchFile.count,
    in_sync: SketchFile.in_sync.count
  })
end

after do
  ActiveRecord::Base.connection.close
end
