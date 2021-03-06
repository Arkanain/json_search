module ORM
  class DBConnection
    attr_accessor :table

    def initialize(caller_model)
      @table_name = caller_model.name.underscore.pluralize.to_sym
      @table_path = "app/services/db/tables/#{@table_name}.json"

      raise ORM::DBError, "Table #{@table_name} doesn't exist." unless File.exist?(@table_path)
    end

    class << self
      # Return DB structure from database.json
      def db_structure
        db_path = 'app/services/db/database.json'
        raise ORM::DBError, "Database file doesn't exist" unless File.exist?(db_path)

        read_and_parse_file(db_path)
      end

      # Read any file and change all keys to symbols in hash and also in all included hashes
      def read_and_parse_file(path)
        json = JSON.parse(File.read(path))
        recursive_symbolize_keys!(json)
      end

      # Generate JSON for DB and write it to database.json file
      def update_db(struct)
        File.write('app/services/db/database.json', JSON.generate(struct))
      end

      def recursive_symbolize_keys!(object)
        case
          when object.is_a?(Hash)
            object.keys.each do |key|
              key_symbol = key.to_sym
              object[key_symbol] = object.delete(key)
              recursive_symbolize_keys! object[key_symbol] if object[key_symbol].kind_of?(Hash)
            end
          when object.is_a?(Array)
            object.each { |item| recursive_symbolize_keys!(item) }
        end

        object
      end

      # This code used for fix custom tables
      def get_field_class(value)
        case
          when value.is_a?(String)
            'string'
          when value.is_a?(Integer)
            'integer'
          when value.is_a?(Float)
            'float'
          when value.is_a?(BigDecimal)
            'decimal'
          when value.is_a?(DateTime)
            'datetime'
          when value.is_a?(FalseClass) || value.is_a?(TrueClass)
            'boolean'
          else
            raise FieldTypeError, 'Invalid field type.'
        end
      end
    end

    # Functionality to work with adding row to DB
    def create_row(hash)
      raise ORM::TableError, "Something went wrong." unless hash[:id].present?

      update_counter(hash[:id])
      result_table = table << hash
      File.write(@table_path, JSON.generate(result_table))
    end

    # Functionality to work with updating row in DB
    def update_row(hash)
      raise ORM::TableError, "Something went wrong." unless hash[:id].present?

      result_table = table.map! { |e| e[:id] == hash[:id] ? e = e.merge!(hash) : e }
      File.write(@table_path, JSON.generate(result_table))
    end

    # Functionality to work with deleting row from DB
    def delete_row(hash)
      raise ORM::TableError, "Something went wrong." unless hash[:id].present?

      result_table = table.delete_if { |e| e[:id] == hash[:id] }
      File.write(@table_path, JSON.generate(result_table))
    end

    # Add field with nil value for each row in DB table
    def add_field(field_name)
      result_table = table.map { |row| row.merge!(field_name => nil) }
      File.write(@table_path, JSON.generate(result_table))
    end

    # Remove field from each row in DB table
    def remove_field(field_name)
      result_table = table.each { |row| row.delete(field_name) }
      File.write(@table_path, JSON.generate(result_table))
    end

    # Getter method for getting counter value
    def counter
      self.class.db_structure[@table_name][:counter]
    end

    # Getter method for getting DB table
    def table
      self.class.read_and_parse_file(@table_path)
    end

    def update_counter(counter)
      database = self.class.db_structure
      database[@table_name][:counter] = counter

      self.class.update_db(database)
    end

    def add_table(new_table_hash)
      new_structure = self.class.db_structure
      new_structure.merge!(new_table_hash)
      self.class.update_db(new_structure)
    end

    def remove_table(table_name)
      new_structure = self.class.db_structure
      new_structure.delete(table_name)
      self.class.update_db(new_structure)
    end

    def add_table_column(name, type)
      # Add column to each row in table
      add_field(name)

      # Add column and return DB structure for table
      db_column_func do |new_struct|
        new_struct[@table_name][:fields].merge!(name => type)
      end
    end

    def remove_table_column(name)
      # Remove column from each row in table
      remove_field(name)

      # Remove column and return DB structure for table
      db_column_func do |new_struct|
        new_struct[@table_name][:fields].delete(name)
      end
    end

    def rename_table_column(old_name, new_name)
      db_column_func do |new_struct|
        new_struct[@table_name][:fields][new_name] = new_struct[@table_name][:fields].delete(old_name)
      end
    end

    def change_table_column(name, new_type)
      db_column_func do |new_struct|
        new_struct[@table_name][:fields][name] = new_type
      end
    end

    private

    # This method remove duplications in code and provide us interface to work with table columns on DB layer.
    def db_column_func(&block)
      new_structure = self.class.db_structure

      yield(new_structure)
      self.class.update_db(new_structure)
      new_structure
    end
  end
end