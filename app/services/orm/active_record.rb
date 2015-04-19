module ORM
  class ActiveRecord
    def save
      db_connection = ORM::DBConnection.new(self.class)

      self.attributes.merge!({id: db_connection.counter + 1}) if new_record

      type = new_record ? :create : :update

      db_connection.update_table(self.attributes, type)
    end

    def update_attributes(attributes)
      attributes.each { |key, value| send("#{key}=", value) }
      save
    end

    def destroy
      db_connection = ORM::DBConnection.new(self.class)
      db_connection.update_table(self.attributes, :delete)
    end

    class << self
      # This attr accessor need for scopes which is declarated in a class
      attr_accessor :scopes

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
          if value.is_a?(String)
            negative = value.first == '-'
            temp_value = negative ? value[1..value.length] : value

            obj = obj.select { |e| negative ^ e[key].downcase.include?(temp_value.downcase) }
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
# 1) implement functionality for migration
# 2) implement relation between tables
# 3) implement validation functionality