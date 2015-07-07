module ORM
  module Associations
    class CollectionProxy
      attr_accessor :collection
      attr_reader :caller_object, :assoc, :type

      def initialize(caller_object, assoc)
        @assoc = assoc
        @caller_object = caller_object

        if assoc.options[:through]
          @type = assoc.source_type.constantize

          through_results = assoc.related_table.constantize.where(assoc.foreign_key => caller_object.send(assoc.primary_key))
          self.collection = where(id: through_results.order(assoc.order_key.to_sym).map { |row| row.send(assoc.source_key) })
        else
          @type = assoc.class_name.constantize
          self.collection = where({ assoc.foreign_key => caller_object.send(assoc.primary_key) }, json_table).order(assoc.order_key).collection
        end

        self.class.include self.type.scopes if self.type.scopes.present?
      end

      def create(hash)
        hash = hash.merge(assoc.foreign_key => caller_object.send(assoc.primary_key))
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
        obj = collection || self.collection

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

      #def <<(records)
      #  puts 123
      #end

      def include?(record)
        to_a.map(&:attributes).include?(record.attributes)
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
end