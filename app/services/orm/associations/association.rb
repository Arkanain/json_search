module ORM
  module Associations
    module Association
      def class_name
        (@options[:class_name] || @relation_name.singularize.camelize).constantize
      end

      def foreign_key
        @options[:foreign_key] || "#{self.name.underscore}_id".to_sym
      end

      #TODO: implement it when validation will be ready
      def validate

      end
    end
  end
end