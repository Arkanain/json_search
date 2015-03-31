module ORM
  class DBConnection
    attr_accessor :table, :fields

    def initialize(caller_model)
      get_table(caller_model)
      get_fields(caller_model)
    end

    def update_table(hash, type)
      # hash is what we will create, update, delete in table
      # type is what we will do with table
    end

    private

    def get_table(caller_model)
      table_name = caller_model.name.downcase.pluralize
      table_path = "app/services/db/#{table_name}.json"

      raise StandardError, "#{table_name} table doesn't exist." unless File.exist?(table_path)

      json = JSON.parse(File.read(table_path))

      if json.first.present? and json.first.keys != json.first.keys.map(&:downcase)
        self.table = json.map!.with_index do |lang, index|
          lang.inject({ id: index }) do |h, (key, value)|
            h.merge(key.downcase.gsub(' ', '_').to_sym => value)
          end
        end

        File.write(table_path, JSON.generate(table))
      else
        self.table = json.map(&:symbolize_keys)
      end
    end

    def get_fields(caller_model)
      table_name = caller_model.name.downcase.pluralize
      db_path = "app/services/db/database.json"
      database = JSON.parse(File.read(db_path))

      if database[table_name].blank?
        db_fields = table.first.inject({}) do |h, (key, value)|
          h.merge(key => value.class.to_s.downcase)
        end

        database.merge!(table_name => db_fields)

        File.write(db_path, JSON.generate(database))
      end

      fields = database[table_name].keys.map(&:to_sym)

      caller_model.instance_eval %(
        attr_accessor #{fields.map{|e| ":#{e}"}.join(', ')}
      )
    end

    #TODO: Need to implement this methods letter for more complex hashes
    #def recursive_symbolize_keys!(object)
    #  object.keys.each do |key|
    #    key_symbol = key.to_sym
    #    object[key_symbol] = object.delete(key)
    #    recursive_symbolize_keys! object[key_symbol] if object[key_symbol].kind_of?(Hash)
    #  end
    #end
  end
end