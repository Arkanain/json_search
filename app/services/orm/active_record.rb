module ORM
  class ActiveRecord
    extend Associations

    def save
      db_connection = ORM::DBConnection.new(self.class)

      if new_record
        self.created_at = Time.now.utc.to_s
        self.updated_at = Time.now.utc.to_s
        db_connection.create_row({
          id: db_connection.counter + 1
        }.merge!(self.attributes) { |key, old_val, new_val| new_val.nil? ? old_val : new_val })
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
        self::ActiveRelation.new(self)
      end

      def find(id)
        self::ActiveRelation.new(self).find(id)
      end

      def where(hash)
        self::ActiveRelation.new(self).where(hash)
      end

      def matches(string, fields)
        self::ActiveRelation.new(self).matches(string, fields)
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
    end
  end
end

#TODO:
# 1) implement validation functionality

#TODO: I will need this for validation
# :string && :text = String = "string"
# :integer = Integer = "integer"
# :float = Float = "float"
# :decimal = BigDecimal = "decimal"
# :datetime && :timestamp && :time && :date = DateTime = "datetime"
# :boolean = FalseClass || TrueClass = "boolean"