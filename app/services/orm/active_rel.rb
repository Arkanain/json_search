module ORM
  module ActiveRel
    attr_accessor :collection, :type

    def initialize(type)
      self.type = type
      self.class.include self.type.scopes if self.type.scopes.present?

      self.collection ||= json_table
    end

    def create(hash)
      type.new(hash).save
    end

    def matches(string, fields)
      type.matches(string, fields, collection)
    end

    def order(field_name)
      collection.sort_by! { |row| row[field_name] }
      self
    end

    def find(id)
      raise ORM::ActiveRecordError, "Couldn't find #{type} without id." if id.blank?

      obj = json_table.find { |e| e[:id] == id.to_i }

      raise ORM::ActiveRecordError, "Couldn't find #{type} with id #{id}" if obj.blank?

      type.new(obj)
    end

    def where(hash, collection = nil)
      obj = collection || json_table

      hash.each do |key, value|
        case
          when value.is_a?(String)
            negative = value.first == '-'
            temp_value = negative ? value[1..value.length] : value

            obj = obj.select { |e| negative ^ e[key].downcase.include?(temp_value.downcase) }
          when value.is_a?(Array)
            obj = obj.select { |e| value.include?(e[key]) }
          else
            obj = obj.select { |e| e[key] == value }
        end
      end

      self.collection = obj
      self
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

      self.collection = results
      self
    end

    def include?(record)
      to_a.map(&:attributes).include?(record.attributes)
    end

    def all
      self
    end

    [:first, :last, :length, :size, :count, :empty?].each do |name, params|
      instance_eval <<-CODE
        define_method("#{name}") do |#{params}|
          to_a.#{name}(#{params})
        end
      CODE
    end

    [:each, :map].each do |name|
      instance_eval <<-CODE
        define_method("#{name}") do |*args, &block|
          to_a.send(name, *args, &block)
        end
      CODE
    end

    private

    def to_a
      objects_array(collection)
    end

    def objects_array(obj)
      obj.inject([]){ |result, lang_hash| result << type.new(lang_hash) }
    end

    def json_table
      ORM::DBConnection.new(type).table
    end
  end
end