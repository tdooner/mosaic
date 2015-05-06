require 'active_record'; ActiveRecord::Base.raise_in_transactional_callbacks = true
require 'haml'
require 'sinatra'
require 'sinatra/json'
require 'threaded'

require_relative 'lib/db_connection'
require_relative 'lib/sketch_sync_dropbox'
require_relative 'lib/setup_sherpa'
require_relative 'models/slice'
require_relative 'models/tagging'
require_relative 'models/sketch_file'

$logger = Logger.new(STDOUT)

# TODO: Fix this to only be images/
set :public_folder, '.'
set :protection, except: [:json_csrf]

configure do
  ActiveRecord::Base.logger = $logger
  SetupSherpa.guide!
  SketchSyncDropbox.authenticate!(ENV['DROPBOX_APP_KEY'], ENV['DROPBOX_APP_SECRET'])
  SketchSyncDB.create_schema unless SketchSyncDB.schema_exists?

  Tagging.initialize_all!

  Threaded.logger = $logger
  Threaded.inline = false
  Threaded.size = 3
  Threaded.start

  SketchFile.sync_all unless ENV['SKIP_SYNC']
end

get '/' do
  haml :index
end

get '/tags' do
  known_paths = SketchFile.all.pluck(:dropbox_path)
  num_files_by_path = known_paths.each_with_object(Hash.new(0)) do |file, count|
    path = File.dirname(file)
    while path != '/'
      count[path] += 1
      path = File.dirname(path)
    end
  end

  haml :tags, locals: {
    num_files_by_path: Hash[num_files_by_path.sort],
    taggings: Tagging.all.pluck(:dropbox_path, :type).to_set,
  }
end

# Toggle whether a path is tagged in some way
post '/tags' do
  tag = Tagging.where(dropbox_path: params[:path],
                      type: params[:tag])

  if Tagging.types.include?(params[:tag].to_sym)
    if tag.exists?
      tag.delete_all
    else
      tag.create
    end
  end

  Tagging.initialize_all!

  json(Tagging.where(dropbox_path: params[:path]))
end

post '/search' do
  # TODO: Make this more sane
  recent_results = Slice.find_by_search(params[:query]).recently_modified
  results = Slice.find_by_search(params[:query]).not_recently_modified

  results_by_file_id = (recent_results + results).group_by(&:sketch_file_id)
  files = SketchFile.where(id: results_by_file_id.keys.uniq).group_by(&:id)

  ranker = ->(results) do
    results = Hash[results.group_by { |s| Tagging.rank_adjustment_for(files[s.sketch_file_id].first.tag_cache) }.sort.reverse]
    results.map { |_score, res| Hash[res.group_by { |s| results_by_file_id[s.sketch_file_id].count }.sort.reverse].values }.flatten
  end

  results = ranker.call(results)
  recent_results = ranker.call(recent_results)

  json({
    search: params[:query],
    results: (recent_results + results).first(300).group_by(&:sketch_file_id).map do |file_id, slices|
      file = files[file_id].first

      { file: file.dropbox_path, tags: file.tag_cache, file_id: file.id, last_modified: file.last_modified, slices: slices }
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
