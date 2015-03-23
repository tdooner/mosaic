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

configure do
  ActiveRecord::Base.logger = $logger
  SketchSyncDropbox.authenticate!(ENV['DROPBOX_APP_KEY'], ENV['DROPBOX_APP_SECRET'])
  SketchSyncDB.create_schema unless SketchSyncDB.schema_exists?

  Threaded.logger = $logger
  Threaded.inline = false
  Threaded.size = 3
  Threaded.start

  SketchFile.sync_all
end

get '/' do
  haml :index
end

post '/search' do
  # TODO: Make this more sane
  recent_results = Slice.find_by_search(params[:query]).recently_modified
  results = Slice.find_by_search(params[:query]).not_recently_modified

  results_by_file_id = (recent_results + results).group_by(&:sketch_file_id)
  results = results.sort_by { |s| results_by_file_id[s.sketch_file_id].count }.reverse

  files = SketchFile.where(id: results_by_file_id.keys.uniq).group_by(&:id)

  json({
    search: [params[:query]],
    results: (recent_results + results).first(300).group_by(&:sketch_file_id).map do |file_id, slices|
      file = files[file_id].first
      { file: file.dropbox_path, file_id: file.id, last_modified: file.last_modified, slices: slices }
    end
  })
end

get '/status' do
  json({
    files: SketchFile.count,
    in_sync: SketchFile.in_sync.count
  })
end

get '/download/:file_id' do |file_id|
  file = SketchFile.find(file_id)
  media = SketchSyncDropbox.with_client do |client|
    client.shares(file.dropbox_path)
  end

  redirect media['url']
end

after do
  ActiveRecord::Base.connection.close
end
