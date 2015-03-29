module Ng
  class ActiveRecord
    def initialize(hash)
      hash.map { |key, value| send("#{key}=", value) }
    end

    class << self
      def all
        Ng::ActiveRelation.new(self, json_table)
      end

      def where(hash, collection = nil)
        obj = collection || json_table

        hash.each do |key, value|
          negative = value.first == '-'
          temp_value = negative ? value[1..value.length] : value

          obj = obj.select { |e| negative ^ e[key].downcase.include?(temp_value.downcase) }
        end

        Ng::ActiveRelation.new(self, obj)
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

        Ng::ActiveRelation.new(self, results)
      end

      def objects_array(obj)
        obj.inject([]){ |result, lang_hash| result << new(lang_hash) }
      end

      def attr_available(*attrs)
        attr_accessor *(attrs << :id)
      end

      private

      def json_table
        JSON.parse(File.read("#{name.downcase.pluralize}.json")).map!.with_index do |lang, index|
          lang.inject({ id: index }) do |h, (key, value)|
            h.merge(key.downcase.gsub(' ', '_').to_sym => value)
          end
        end
      end
    end
  end
end