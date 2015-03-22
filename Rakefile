namespace :db do
  task :environment do
    require_relative 'lib/db_connection'
  end

  desc 'Drop all tables from the sqlite db'
  task drop: :environment do
    SketchSyncDB.drop_schema
  end

  desc 'Create all table in the sqlite db'
  task create: :environment do
    SketchSyncDB.create_schema
  end
end
