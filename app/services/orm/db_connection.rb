module ORM
  class DBConnection
    attr_accessor :table

    def initialize(caller_model)
      @table_name = caller_model.name.downcase.pluralize.to_sym
      @table_path = "app/services/db/tables/#{@table_name}.json"
      @db_path = 'app/services/db/database.json'

      raise ORM::DBError, "Table doesn't exist." unless File.exist?(@table_path)
      raise ORM::DBError, "Database file doesn't exist" unless File.exist?(@db_path)
    end

    def update_table(hash, type)
      if hash[:id].present?
        result_table = case type
                        when :create
                          update_counter(hash[:id])
                          table << hash
                        when :update
                          table.map! { |e| e[:id] == hash[:id] ? e = e.merge!(hash) : e }
                        when :delete
                          table.delete_if { |e| e[:id] == hash[:id] }
                       end

        File.write(@table_path, JSON.generate(result_table))
      else
        raise ORM::TableError, "Something went wrong."
      end
    end

    def counter
      db_structure[@table_name][:counter]
    end

    def table
      read_and_parse_file(@table_path)
    end

    def db_structure
      read_and_parse_file(@db_path)
    end

    def add_db_structure(new_table_hash)
      new_structure = db_structure.merge!(new_table_hash)
      update_db(new_structure)
    end

    def remove_db_structure(table_name)
      new_structure = db_structure
      new_structure.delete(table_name)
      update_db(new_structure)
    end

    private

    def read_and_parse_file(path)
      json = JSON.parse(File.read(path))
      recursive_symbolize_keys!(json)
    end

    def update_counter(counter)
      database = db_structure
      database[@table_name][:counter] = counter

      update_db(database)
    end

    def update_db(struct)
      File.write(@db_path, JSON.generate(struct))
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
  end
end