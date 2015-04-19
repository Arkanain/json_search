namespace :db do
  task :create do
    db_path = "app/services/db/database.json"

    raise ORM::DBError, "Database already exist." if File.exist?(db_path)

    File.open(db_path, 'w+') { |f| f << '{}' }
  end

  task :drop do
    Dir["app/services/db/tables/*.json"].each do |table_path|
      File.delete(table_path)
    end

    File.delete("app/services/db/database.json")
  end

  task :migrate => :environment do
    Dir[Rails.root.join('app/services/db/migrate/*.rb')].sort.each do |migration|
      file_name = File.basename(migration, '.rb').split('_')
      migration_number = file_name.first
      migration_class = (file_name - [migration_number]).join('_').camelize

      require migration

      migration_class.constantize.new.up
    end
  end

  task :rollback => :environment do
    Dir[Rails.root.join('app/services/db/migrate/*.rb')].sort.each do |migration|
      file_name = File.basename(migration, '.rb').split('_')
      migration_number = file_name.first
      migration_class = (file_name - [migration_number]).join('_').camelize

      require migration

      migration_class.constantize.new.down
    end
  end
end