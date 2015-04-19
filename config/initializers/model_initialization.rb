require 'orm/project_error'

db_path = "app/services/db/database.json"

raise ORM::DBError, "Database doesn't exist. Please run rake db:create to initialize it." unless File.exist?(db_path)

database = JSON.parse(File.read(db_path))

# This code is rewrite each of our incoming json tables and create for them structure in database.json
Dir[Rails.root.join("app/services/db/tables/*.json")].each do |table_path|
  json = JSON.parse(File.read(table_path))

  #Override default table and add id for each field in it
  if json.first.present? and json.first.keys != json.first.keys.map(&:downcase)
    table = json.map!.with_index do |rows, index|
      rows.inject({ id: index }) do |h, (key, value)|
        h.merge(key.downcase.gsub(' ', '_').to_sym => value)
      end
    end

    File.write(table_path, JSON.generate(table))
  end

  # This code added DB structure to database.json if structure doesn't exist
  # In structure I mean that I added all fields types and table counter
  table_name = File.basename(table_path, '.json')
  if database[table_name].blank?
    db_fields = table.first.inject({}) do |h, (key, value)|
      h.merge(key => value.class.to_s.downcase)
    end

    database.merge!(
      table_name => {
        'counter' => (table.length - 1),
        'fields' => db_fields
      }
    )
  end

  # If model file doesn't exist in services/models directory this code will create it
  model_path = "#{Rails.root}/app/services/models/#{table_name.singularize}.rb"

  unless File.exist?(model_path)
    File.open(model_path, 'w+') do |f|
      f << "class #{table_name.singularize.titleize} < ORM::ActiveRecord\nend"
    end
  end
end

# Write final DB structure to database.json
File.write(db_path, JSON.generate(database))

#Init DB and set instance methods for each model in models directory
Dir[Rails.root.join("app/services/models/*.rb")].each { |f| require f }

database.each do |table_source|
  ORM::ModelInit.init(table_source)
end