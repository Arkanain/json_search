module ORM
  class Migration
    def create_table(name, &block)
      @fields = {}

      yield(self)

      db_structure = {
        name.to_s => {
          'counter' => 0,
          'fields' => @fields
        }
      }

      File.open("app/services/db/tables/#{name}.json", 'w+') { |f| f << '[]' }

      ORM::DBConnection.new(name.to_s.singularize.camelize.constantize).add_db_structure(db_structure)
      ORM::ModelInit.init(db_structure.first)
    end

    def drop_table(name)
      model_file = name.to_s.singularize
      model_name = model_file.camelize
      ORM::DBConnection.new(model_name.constantize).remove_db_structure(name)

      File.delete("app/services/db/tables/#{name}.json")
    end

    def column(name, type)
      @fields.merge!(name => type.to_s)
    end
  end
end