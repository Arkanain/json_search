class ModelGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  argument :model_name, type: :string, required: true

  def create_model_file
    raise ORM::ModelError, 'Model name should have singular name' if model_name == model_name.pluralize

    template 'model.erb', "app/services/models/#{correct_model_name}.rb"
  end

  def create_migration_file
    template 'migration.erb', "app/services/db/migrate/#{Time.now.gmtime.strftime('%Y%m%d%H%M%S')}_create_#{correct_model_name.pluralize}.rb"
  end

  private

  def correct_model_name
    model_name.underscore
  end
end
