require 'active_record'; ActiveRecord::Base.raise_in_transactional_callbacks = true
require 'haml'
require 'sinatra'
require 'sinatra/json'
require 'threaded'

Dir["app/**/*.rb"].each { |f| require_relative f }

$logger = Logger.new(STDOUT)
$logger.level = Logger::INFO unless ENV['DEBUG']

# TODO: Fix this to only be images/
set :public_folder, '.'
set :protection, except: [:json_csrf]

configure do
  ActiveRecord::Base.logger = $logger
  SetupSherpa.guide!
  DropboxWrapper.authenticate!(ENV['DROPBOX_APP_KEY'], ENV['DROPBOX_APP_SECRET'])
  MosaicDB.create_schema unless MosaicDB.schema_exists?

  # SketchPage.load_from_path(File.expand_path('~/downloads/ftuflow'))
  Threaded.logger = $logger
  Threaded.inline = false
  Threaded.size = 3
  Threaded.start

  Threaded.enqueue(DropboxSyncWorker)

  # unless ENV['SKIP_SYNC']
  #   SketchFile.sync_all
  #   Threaded.enqueue(SketchFile::StartSyncManagerThread)
  # end
end

get '/' do
  haml :index
end

# get '/pages/:id/slice/:coords' do
#   x, y = params[:coords].split(',').map(&:to_f)
# 
#   file = SketchPage.find(params[:id]).sketch_artboards.detect do |slice|
#     left, top, right, bottom = slice.bounds.split(',').map(&:to_f)
# 
#     left < x && x < right && top < y && y < bottom
#   end
# 
#   return json({ slice: nil }) unless file
#   json({ slice: file.name })
# end

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
  search_tokens = params[:query].split(/[^\w]/)
  search_tokens.map! { |t| "#{t}*" }

  pages = SketchPage.
            joins('JOIN pages_fts ON pages_fts.page_id = sketch_pages.id').
            where('pages_fts.body MATCH ?', search_tokens)
  artboards = SketchArtboard.
                includes(sketch_page: :sketch_file).
                joins('JOIN artboards_fts ON artboards_fts.artboard_id = sketch_artboards.id').
                where('artboards_fts.body MATCH ?', search_tokens)

  pages_by_file = pages.group_by(&:sketch_file_id)
  artboards_by_page = artboards.group_by(&:sketch_page_id)

  # find the file with the most pages and artboards:
  # arbitrarily, this rates pages that match 3x heavier than artboards that do.
  scores_by_file_id = Hash.new(0)
  scores_by_page_id = Hash.new(0)
  pages_by_file.each do |file_id, pages|
    scores_by_file_id[file_id] = 3 * pages.length
  end
  artboards_by_page.each do |page_id, artboards|
    artboards.each do |artboard|
      file_id = artboard.sketch_page.sketch_file_id
      scores_by_file_id[file_id] += 1
      scores_by_page_id[artboard.sketch_page_id] += 1
    end
  end

  files = SketchFile.where(id: scores_by_file_id.keys).includes(:sketch_pages).index_by(&:id)

  results = scores_by_file_id.sort_by(&:last).reverse.first(20).flat_map do |file_id, _score|
    file = files[file_id]
    page_results = pages_by_file.fetch(file_id, []).map do |page|
      {
        file: file.dropbox_path,
        file_id: file_id,
        last_modified: file.last_modified,
        type: :page,
        page: page,
      }
    end
    matching_artboards = artboards_by_page.values_at(*file.sketch_pages.map(&:id)).compact.flatten
    artboard_results = matching_artboards.map do |artboard|
      {
        file: file.dropbox_path,
        file_id: file_id,
        last_modified: file.last_modified,
        type: :artboard,
        artboard: artboard,
      }
    end

    page_results + artboard_results
  end

  json({
    search: params[:query],
    results: results,
  })
end

# post '/search' do
#   # TODO: Make this more sane
#   recent_results = Slice.find_by_search(params[:query]).recently_modified
#   results = Slice.find_by_search(params[:query]).not_recently_modified
#
#   results_by_file_id = (recent_results + results).group_by(&:sketch_file_id)
#   files = SketchFile.where(id: results_by_file_id.keys.uniq).group_by(&:id)
#
#   ranker = ->(results) do
#     results = Hash[results.group_by { |s| Tagging.rank_adjustment_for(files[s.sketch_file_id].first.tag_cache) }.sort.reverse]
#     results.map { |_score, res| Hash[res.group_by { |s| results_by_file_id[s.sketch_file_id].count }.sort.reverse].values }.flatten
#   end
#
#   results = ranker.call(results)
#   recent_results = ranker.call(recent_results)
#
#   json({
#     search: params[:query],
#     results: (recent_results + results).first(300).group_by(&:sketch_file_id).map do |file_id, slices|
#       file = files[file_id].first
#
#       { file: file.dropbox_path, tags: file.tag_cache, file_id: file.id, last_modified: file.last_modified, slices: slices }
#     end
#   })
# end

get '/status' do
  # TODO: remove
  return json({ files: 1, in_sync: 1 })
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
