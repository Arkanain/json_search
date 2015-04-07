db_path = "app/services/db/database.json"

# If database.json doesn't exist then I create empty database.json with default empty hash inside it
unless File.exist?(db_path)
  File.open("#{Rails.root}/#{db_path}", "w+") do |f|
    f << "{}"
  end
end

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
    File.open(model_path, "w+") do |f|
      f << "class #{table_name.singularize.titleize} < ORM::ActiveRecord\nend"
    end
  end
end

# Write final DB structure to database.json
File.write(db_path, JSON.generate(database))

#Init DB and set instance methods for each model in models directory
Dir[Rails.root.join("app/services/models/*.rb")].each { |f| require f }

database.each do |table_name, inner|
  column_types = inner['fields'].symbolize_keys
  model = table_name.singularize.titleize.constantize

  # There we setup two basical fields
  # attributes - for model attributes
  # column_types - for model column and their types
  model.instance_eval do
    attr_reader :attributes, :column_types, :new_record

    # This method need to provide object to RESTfull links
    # For example:
    # @language = Language.find(1)
    # = link_to 'Language', language_path(@language)
    define_method(:to_param) do
      attributes[:id].to_s
    end

    # This method need for form_for to generate different id and url options depends on :id parametr
    define_method(:to_key) do
      [attributes[:id]] if attributes[:id]
    end

    # This method need for form_for to understand which type of HTTP method we should use and also for prefix in id attribute
    # if new record then form_for will setup method: :post and id prefix: :new
    # if not new record then form_for will setup method: :put(:patch) and id prefix: :edit
    define_method(:persisted?) do
      !new_record
    end
  end

  # There I create class constructor and add getter and setter methods for all fields in a table
  model.class_eval do
    # This part need firstly for passing column types from outer code,
    # secondary - each class should have info about fields and their types
    @column_types = column_types

    # model_name variable needs for generate all needed params in form_for without our help
    @model_name = ORM::ActiveNaming.new(self)

    class << self
      attr_reader :column_types, :model_name
    end

    def initialize(common_attrs = nil)
      @column_types = self.class.column_types

      # This variable create hash with empty values for all fields in a model
      default_values = @column_types.inject({}) { |h, (key, value)| h.merge(key => nil) }
      @attributes = common_attrs ? default_values.merge(common_attrs.to_hash.symbolize_keys) : default_values

      # Inside of this each I create getter and setter methods for each field in a model
      # Actually I set getter and setter for each field in attributes hash
      # but in case of regular convention lets tell that I create getter and setter for fields in model
      @attributes.each do |key, value|
        self.class.instance_eval do
          define_method(key) do
            attributes[key]
          end

          unless key == :id
            define_method("#{key}=") do |value|
              attributes[key] = value
            end
          end
        end
      end

      # This attribute tell us is record new of it's already present in a system
      @new_record = attributes[:id].blank?
    end
  end
end