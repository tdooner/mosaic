require 'sinatra'
require 'sinatra/json'
require 'haml'
require 'active_record'

# TODO: Fix this to only be images/
set :public_folder, '.'

ActiveRecord::Base.logger = Logger.new(STDOUT)
def recreate_schema
  ActiveRecord::Base.connection.execute <<-SQL.strip
    DROP TABLE IF EXISTS files;
    DROP TABLE IF EXISTS slices;
SQL
  ActiveRecord::Base.connection.execute <<-SQL.strip
    CREATE TABLE files (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      dropbox_path VARCHAR(256) NOT NULL
    );
    CREATE VIRTUAL TABLE slices USING fts4(
      file_id INTEGER NOT NULL,
      path VARCHAR(256) NOT NULL,
      layer VARCHAR(256) NOT NULL,
      tokenize=simple
    );
SQL
end

def schema_exists?
  ActiveRecord::Base.connection.tables.include?('images')
end

CHANGED_FILES = [
]

class File < ActiveRecord::Base
  has_many :images
end

class Slice < ActiveRecord::Base
  def self.find_by_search(query)
    search_tokens = query.split(/[^\w]/)
    search_tokens.map! { |t| "#{t}*" }

    # TODO: Parameterize this query:
    Image.find_by_sql("SELECT * FROM slices WHERE slices MATCH \"#{search_tokens.join(' ')}\";")
  end
end

def index_changes(changes)
  puts changes.inspect
  Slice.transaction do
    changes.each do |change|
      Slice.where(path: change[:path], layer: change[:layer_tokens].join(' ')).first_or_create
    end
  end
end

configure do
  ENV['DATABASE_URL'] ||= 'sqlite3:db/development.sqlite3'

  ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
  ActiveRecord::Base.connection.verify!

  recreate_schema
  # create_schema unless schema_exists?

  Thread.new { index_changes(CHANGED_FILES) }
end

get '/' do
  haml :index
end

post '/search' do
  results = Image.find_by_search(params[:query])

  json({
    search: [params[:query]],
    results: results.map { |r| { path: r.path, layer: r.layer, tokens: []} }
  })
end

after do
  ActiveRecord::Base.connection.close
end
