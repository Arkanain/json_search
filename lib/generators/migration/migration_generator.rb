class MigrationGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  argument :migration_name, type: :string, required: true

  def create_migration_file
    template 'migration.erb', "app/services/db/migrate/#{Time.now.gmtime.strftime('%Y%m%d%H%M%S')}_#{migration_name.underscore}.rb"
  end
end
