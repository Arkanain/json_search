module ORM
  class DBConnection
    attr_accessor :table, :fields, :counter

    def initialize(caller_model)
      get_table(caller_model)
      get_fields(caller_model)
    end

    def update_table(caller_model, hash, type)
      table_name = caller_model.name.downcase.pluralize
      table_path = "app/services/db/#{table_name}.json"

      result_table = case type
                      when :create
                        update_counter(caller_model, hash[:id])
                        table << hash
                      when :update

                      when :delete

                     end

      File.write(table_path, JSON.generate(result_table))
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

        database.merge!(
          table_name => {
            'counter' => (table.length - 1),
            'fields' => db_fields
          }
        )

        File.write(db_path, JSON.generate(database))
      end

      self.fields = database[table_name]['fields'].keys.map(&:to_sym)
      self.counter = database[table_name]['counter']

      caller_model.instance_eval %(
        attr_accessor #{fields.map{|e| ":#{e}"}.join(', ')}
      )
    end

    def update_counter(caller_model, counter)
      table_name = caller_model.name.downcase.pluralize
      db_path = "app/services/db/database.json"
      database = JSON.parse(File.read(db_path))

      database[table_name]['counter'] = counter

      File.write(db_path, JSON.generate(database))
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