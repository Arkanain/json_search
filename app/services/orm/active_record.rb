module ORM
  class ActiveRecord
    def create
      db_connection = ORM::DBConnection.new(self.class)

      self.id = db_connection.counter + 1
      db_connection.update_table(self.attributes, :create)
    end

    def update_attributes(attributes)
      db_connection = ORM::DBConnection.new(self.class)

      attributes.each { |key, value| send("#{key}=", value) }
      db_connection.update_table(self.attributes, :update)
    end

    def destroy
      db_connection = ORM::DBConnection.new(self.class)
      db_connection.update_table(self.attributes, :delete)
    end

    class << self
      def all
        ORM::ActiveRelation.new(self, json_table)
      end

      def find(id)
        obj = json_table.find { |e| e[:id] == id.to_i }

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

        ORM::ActiveRelation.new(self, obj)
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

        ORM::ActiveRelation.new(self, results)
      end

      def create(hash)
        new(hash).create
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