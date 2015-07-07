module ORM
  class ModelInit
    def self.init(table_source)
      table_name, table_inner = table_source
      column_types = table_inner[:fields].symbolize_keys
      model = table_name.to_s.singularize.camelize.constantize

      # Include ActiveRelation uniq for each model
      unless model.constants.include?(:ActiveRelation)
        model.const_set(:ActiveRelation, Class.new {
          include ORM::ActiveRel
        })
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

              # I don't create attr_writer for :id field because I don't want to leave user any possibility to change this field
              unless key == :id
                define_method("#{key}=") do |value|
                  attributes[key] = value
                end
              end
            end
          end

          # This attribute tell us is record new of it's already present in a system.
          @new_record = attributes[:id].blank?
        end

        # This functionality needs to include scoping methods to our class.
        # We thrown an error when the class already contains a method with the same name as any of scopes in class.
        # Also you can see in list of dangerous methods method :name. Its because we need and we use this method for class
        # in different parts of code and its not a good idea to override it.
        if self.scopes.present?
          matched_methods = self.scopes.instance_methods & (self.methods - Object.methods + [:name])
          if matched_methods.empty?
            extend scopes
          else
            raise ORM::ModelError, "Name already taken. Please rename your scopes - #{matched_methods.join(', ')}."
          end
        end
      end

      # There we setup few basical fields
      # attributes - for model attributes
      # column_types - for model column and their types
      # new_record - boolean value which tell us is we work with newly created model or not
      model.instance_eval do
        attr_reader :attributes, :column_types, :new_record

        # This method need to provide object to RESTfull links
        # For example:
        # @language = Language.find(1)
        # = link_to 'Language', language_path(@language)
        define_method(:to_param) do
          attributes[:id].to_s
        end

        # This method need for form_for to generate different id and url options depends on :id parameter
        define_method(:to_key) do
          [attributes[:id]] if attributes[:id]
        end

        # This method need for form_for to understand which type of HTTP method we should use and also for prefix in id attribute
        # if new record then form_for will setup method: :post and id prefix: :new
        # if not new record then form_for will setup method: :put(:patch) and id prefix: :edit
        define_method(:persisted?) do
          !new_record
        end

        # This functionality needs to include relations methods to our instance.
        # We thrown an error when the instance already contains a method with the same name as any of relations in instance.
        # Also you can see in list of dangerous methods method :name. Its because we need and we use this method for class
        # in different parts of code and its not a good idea to override it.
        if self.relations.present?
          matched_methods = self.relations.instance_methods & (self.methods - Object.methods + [:name])

          if matched_methods.empty?
            include relations
          else
            raise ORM::ModelError, "Name already taken. Please rename your relation name - #{matched_methods.join(', ')}."
          end
        end
      end
    end
  end
end