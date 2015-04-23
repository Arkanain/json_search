namespace :db do
  task :create do
    db_path = 'app/services/db/database.json'

    raise ORM::DBError, 'Database already exist.' if File.exist?(db_path)

    File.open(db_path, 'w+') { |f| f << '{}' }
  end

  task :drop do
    Dir['app/services/db/tables/*.json'].each do |table_path|
      File.delete(table_path)
    end

    File.delete('app/services/db/database.json')
  end

  task :migrate => :environment do
    schema_path = 'app/services/db/schema.json'

    # If file exist we take data from it and get latest migration number
    if File.exist?(schema_path)
      schema = JSON.parse(File.read(schema_path))
      latest = schema.last ? schema.last.first : 0
    else
      schema = []
      latest = 0
      File.open(schema_path, 'w+') { |f| f << schema }
    end

    # Check all migrations in db/migrate folder and choose only migrations which are not runned
    latest_migrations = Dir[Rails.root.join('app/services/db/migrate/*.rb')].select do |f|
      File.basename(f).split('_').first.to_i > latest
    end

    # If we found not runned migrations then we run it.
    # Push to schema new info about latest runned migration and how much migrations we runned.
    if latest_migrations.present?
      latest_migrations.each do |migration|
        file_name = File.basename(migration, '.rb').split('_')
        latest = file_name.first
        migration_class = (file_name - [latest]).join('_').camelize

        require migration

        migration_class.constantize.new.up
      end

      schema.push([latest.to_i, latest_migrations.count])
      File.write(schema_path, JSON.generate(schema))
    end
  end

  task :rollback => :environment do
    schema_path = 'app/services/db/schema.json'
    schema = JSON.parse(File.read(schema_path))

    # Get list of migrations and reverse it to facilitate processing
    all_migrations = Dir[Rails.root.join('app/services/db/migrate/*.rb')].reverse!
    latest_index = all_migrations.index { |m| m.include?(schema.last.first.to_s) }
    latest_migrations = all_migrations[latest_index, schema.last.last]

    # Run all migrations for rollback
    # Pop last element from array of arrays
    latest_migrations.each do |migration|
      file_name = File.basename(migration, '.rb').split('_')
      migration_number = file_name.first
      migration_class = (file_name - [migration_number]).join('_').camelize

      require migration

      migration_class.constantize.new.down
    end

    schema.pop
    File.write(schema_path, JSON.generate(schema))
  end
end