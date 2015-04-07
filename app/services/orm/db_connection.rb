module ORM
  class DBConnection
    attr_accessor :table

    def initialize(caller_model)
      @table_name = caller_model.name.downcase.pluralize.to_sym
      @table_path = "app/services/db/tables/#{@table_name}.json"
      @db_path = 'app/services/db/database.json'
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
        raise StandardError, "Something went wrong."
      end
    end

    def counter
      read_and_parse_file(@db_path)[@table_name][:counter]
    end

    def table
      read_and_parse_file(@table_path)
    end

    private

    def read_and_parse_file(path)
      json = JSON.parse(File.read(path))
      recursive_symbolize_keys!(json)
    end

    def update_counter(counter)
      database = read_and_parse_file(@db_path)
      database[@table_name][:counter] = counter

      File.write(@db_path, JSON.generate(database))
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
          object.each do |item|
            recursive_symbolize_keys!(item)
          end
      end

      object
    end
  end
end