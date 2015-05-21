require 'active_record'

ENV['DATABASE_URL'] ||= 'sqlite3:db/development.sqlite3'

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
ActiveRecord::Base.connection.tap(&:verify!)

module MosaicDB
  def schema_exists?
    ActiveRecord::Base.connection.tables.include?('mosaic_files')
  end

  def create_schema
    load File.expand_path('../../../db/schema.rb', __FILE__)
  end

  def drop_schema
    %w[sketch_files slices].each do |t|
      ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS #{t};"
    end
  end

  module_function :schema_exists?, :create_schema, :drop_schema
end
