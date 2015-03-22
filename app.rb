require 'active_record'
require 'haml'
require 'sinatra'
require 'sinatra/json'
require 'threaded'

require_relative 'lib/db_connection'
require_relative 'lib/sketch_sync_dropbox'
require_relative 'models/slice'
require_relative 'models/sketch_file'

$logger = Logger.new(STDOUT)

# TODO: Fix this to only be images/
set :public_folder, '.'

# def index_changes(changes)
#   Slice.transaction do
#     changes.each do |change|
#       s = SketchFile.where(dropbox_path: change[:original_path]).first_or_create(dropbox_rev: change[:rev])
#       Slice.where(
#         sketch_file: s,
#         path: change[:path],
#         layer: change[:layer_tokens].join(' ')
#       ).first_or_create
#     end
#   end
# end

configure do
  ActiveRecord::Base.logger = $logger
  SketchSyncDropbox.authenticate!(ENV['DROPBOX_APP_KEY'], ENV['DROPBOX_APP_SECRET'])
  SketchSyncDB.create_schema unless SketchSyncDB.schema_exists?

  Threaded.logger = $logger
  Threaded.inline = false
  Threaded.start

  SketchFile.sync_all
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
