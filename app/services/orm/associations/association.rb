module ORM
  module Associations
    class Association
      class << self
        def new
          return nil
        end

        def class_name
          @options[:class_name] || @relation_name.singularize.camelize
        end

        def foreign_key
          @options[:foreign_key] || "#{@current_object.name.underscore}_id".to_sym
        end

        #TODO: implement it when validation will be ready
        def validate

        end
      end
    end
  end
end