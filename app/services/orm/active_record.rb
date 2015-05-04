module ORM
  class ActiveRecord
    extend Associations

    def save
      db_connection = ORM::DBConnection.new(self.class)

      if new_record
        self.created_at = Time.now.utc.to_s
        self.updated_at = Time.now.utc.to_s
        db_connection.create_row({id: db_connection.counter + 1}.merge!(self.attributes))
      else
        self.updated_at = Time.now.utc.to_s
        db_connection.update_row(self.attributes)
      end

      self
    end

    def update_attributes(attributes)
      attributes.each { |key, value| update_attribute(key, value) }
    end

    def update_attribute(name, value)
      send("#{name}=", value)
      save
    end

    def destroy
      db_connection = ORM::DBConnection.new(self.class)
      db_connection.delete_row(self.attributes)
      self
    end

    class << self
      # This attr accessor need for scopes which is declared in a class
      attr_accessor :scopes, :relations

      def first
        all.first
      end

      def last
        all.last
      end

      def all
        self::ActiveRelation.new(self, json_table)
      end

      def find(id)
        obj = json_table.find { |e| e[:id] == id.to_i }

        raise ORM::ActiveRecordError, "Couldn't find #{self} with id #{id}" if obj.blank?

        new(obj)
      end

      def where(hash, collection = nil)
        obj = collection || json_table

        hash.each do |key, value|
          case
            when value.is_a?(String)
              negative = value.first == '-'
              temp_value = negative ? value[1..value.length] : value

              obj = obj.select { |e| negative ^ e[key].downcase.include?(temp_value.downcase) }
            when value.is_a?(Array)
              obj = obj.select { |e| value.include?(e[key]) }
            else
              obj = obj.select { |e| e[key] == value }
          end
        end

        self::ActiveRelation.new(self, obj)
      end

      def matches(string, fields, collection = nil)
        results = []
        objects = collection || json_table

        objects.each do |lang|
          approved = false

          fields.each do |field|
            unless approved
              substrings = string.downcase.split(' ')
              approved = substrings.all? { |substr| lang[field].downcase.include?(substr) }

              results << lang if approved
            end
          end
        end

        self::ActiveRelation.new(self, results)
      end

      def create(hash)
        new(hash).save
      end

      def scope(name, lambda)
        # Initialize empty module as a contianer for scope functions.
        self.scopes ||= Module.new

        self.scopes.module_eval do
          define_method(name.to_sym, &lambda)
        end
      end

      def has_one(relation_name)
        raise ORM::ModelError, 'has_one relation should have model singular name' if relation_name.to_s == relation_name.to_s.pluralize

        self.relations ||= Module.new

        self.relations.module_eval do
          define_method(relation_name) do
            relation_name.to_s.camelize.constantize.where("#{self.class.name.underscore}_id".to_sym => self.id).first
          end

          define_method("#{relation_name}=") do |value|
            value.update_attribute("#{self.class.name.underscore}_id".to_sym, self.id)
          end
        end
      end

      def belongs_to(relation_name)
        raise ORM::ModelError, 'belongs_to relation should have model singular name' if relation_name.to_s == relation_name.to_s.pluralize

        self.relations ||= Module.new

        self.relations.module_eval do
          define_method(relation_name) do
            relation_name.to_s.camelize.constantize.find(self.send("#{relation_name}_id"))
          end

          define_method("#{relation_name}=") do |value|
            self.update_attribute("#{relation_name}_id".to_sym, value.id)
          end
        end
      end

      def objects_array(obj)
        obj.inject([]){ |result, lang_hash| result << new(lang_hash) }
      end

      private

      def json_table
        ORM::DBConnection.new(self).table
      end
    end
  end
end

#TODO:
# 1) implement relation between tables
# 2) implement validation functionality

#TODO: I will need this for validation
# :string && :text = String = "string"
# :integer = Integer = "integer"
# :float = Float = "float"
# :decimal = BigDecimal = "decimal"
# :datetime && :timestamp && :time && :date = DateTime = "datetime"
# :boolean = FalseClass || TrueClass = "boolean"