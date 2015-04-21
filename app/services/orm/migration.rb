module ORM
  class Migration
    # This method provides functionality to add table to db
    # Example:
    #   create_table :users do |t|
    #     t.string :first_name
    #     t.string :last_name
    #   end
    def create_table(name, &block)
      exist(name)
      @fields = {}

      yield(self)

      db_structure = {
        name.to_s => {
          counter: 0,
          fields: @fields
        }
      }

      File.open("app/services/db/tables/#{name}.json", 'w+') { |f| f << '[]' }

      ORM::DBConnection.new(model_name(name)).add_table(db_structure)
      ORM::ModelInit.init(db_structure.first)
    end

    # This method provides functionality to remove table from db
    # Example: drop_table(:users)
    def drop_table(name)
      not_exist(name)

      ORM::DBConnection.new(model_name(name)).remove_table(name)
      File.delete("app/services/db/tables/#{name}.json")
    end

    # This method provides functionality to add column to existant table
    # Example: add_column(:users, :email, :string)
    def add_column(table_name, field_name, field_type)
      field_type = correct_field_type(field_type)

      column_functional(table_name) do
        add_table_column(field_name, field_type)
      end
    end

    # This method provides functionality to remove column from existant table
    # Example: remove_column(:users, :email)
    def remove_column(table_name, field_name)
      column_functional(table_name) do
        remove_table_column(field_name)
      end
    end

    # This method provides functionality to rename column in existant table
    # Example: rename_column(:users, :email, :work_email)
    def rename_column(table_name, old_name, new_name)
      column_functional(table_name) do
        rename_table_column(old_name, new_name)
      end
    end

    # This method provides functionality to change column type in existant table
    # Example: change_column(:users, :info, :text)
    def change_column(table_name, name, new_type)
      column_functional(table_name) do
        change_table_column(name, new_type)
      end
    end

    # This method is for create_table method. It take us posibility to add column for new table
    # t.column :first_name, :string
    def column(name, type)
      @fields.merge!(name => type.to_s)
    end

    # Methods from >> to << take us posibility to write less code in create_table
    # Example: t.string :first_name
    #>>
    [:string, :text].each do |column_type|
      define_method column_type do |field_name|
        column(field_name, :string)
      end
    end

    define_method :integer do |field_name|
      column(field_name, :integer)
    end

    define_method :float do |field_name|
      column(field_name, :float)
    end

    define_method :decimal do |field_name|
      column(field_name, :decimal)
    end

    [:datetime, :timestamp, :time, :date].each do |column_type|
      define_method column_type do |field_name|
        column(field_name, :datetime)
      end
    end

    define_method :boolean do |field_name|
      column(field_name, :boolean)
    end
    #<<

    #This method is for create timestumps
    def timestamps
      column(:created_at, :datetime)
      column(:updated_at, :datetime)
    end

    private

    # This method remove duplications in code and provide us interface to work with table columns.
    def column_functional(table_name, &block)
      not_exist(table_name)

      db_structure = ORM::DBConnection.new(model_name(table_name)).instance_exec(&block)
      ORM::ModelInit.init([table_name, db_structure[table_name]])
    end

    def model_name(name)
      name.to_s.singularize.camelize.constantize
    end

    def correct_field_type(type)
      case
        when type == :string || type == :text
          'string'
        when type == :integer
          'integer'
        when type == :float
          'float'
        when type == :decimal
          'decimal'
        when type == :datetime || type == :timestamp || type == :time || type == :date
          'datetime'
        when type == :boolean
          'boolean'
        else
          raise FieldTypeError, 'Invalid field type.'
      end
    end

    # Prevent duplication for needed errors
    def not_exist(name)
      raise TableError, "Table #{name} doesn't exist." unless File.exist?("app/services/db/tables/#{name}.json")
    end

    # Prevent duplication for needed errors
    def exist(name)
      raise TableError, "Table #{name} already exist." if File.exist?("app/services/db/tables/#{name}.json")
    end
  end
end