module ORM
  module InstanceQuerying
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
  end
end