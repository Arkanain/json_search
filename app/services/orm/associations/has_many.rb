module ORM
  module Associations
    module HasMany
      include CollectionAssociation

      def has_many(relation_name, options={})
        @relation_name = relation_name.to_s
        @options = options

        raise ORM::ModelError, 'has_many relation should have model plural name' if @relation_name == @relation_name.singularize

        if @options[:source] && (@options[:source].to_s == @options[:source].to_s.pluralize)
          raise ORM::ModelError, ":source option for relation has_many :#{@relation_name} in #{self} model should have singular name"
        end

        if @options[:source_type] && !Object.const_defined?(@options[:source_type])
          raise ORM::ModelError, "Can't find class which is specified for :source_type option for relation has_many :#{@relation_name} in #{self} model"
        end

        self.relations ||= Module.new

        if @options[:through].present?
          #If we have :through option then let's define special method for it
          define_through_options

          self.relations.module_eval <<-CODE
            define_method("#{@relation_name}") do
              #{@options[:through]} = #{related_table}.where(#{foreign_key}: self.#{primary_key})

              #{source_type}.where(id: #{@options[:through]}.map(&:#{source_key}))
            end

            define_method("#{@relation_name}=") do |value|
              #{@options[:through]} = #{related_table}.where(#{foreign_key}: self.#{primary_key}).map(&:#{source_key})

              value = [value] unless value.is_a?(Array)

              new_authors = value.map(&:id) - #{@options[:through]}
              new_authors.each do |author_id|
                #{related_table}.create(#{foreign_key}: self.#{primary_key}, #{source_key}: author_id)
              end
            end
          CODE
        else
          self.relations.module_eval <<-CODE
            define_method("#{@relation_name}") do
              #{class_name}.where(#{foreign_key}: self.#{primary_key})
            end

            define_method("#{@relation_name}=") do |value|
              value.each do |row|
                row.update_attribute(:#{foreign_key}, self.#{primary_key})
              end
            end
          CODE
        end
      end

      private

      #def as
      #
      #end

      #def dependent
      #
      #end

      def foreign_key
        "#{self.name.underscore}_id".to_sym
      end

      def primary_key
        @options[:primary_key].present? ? @options[:primary_key].to_sym : :id
      end

      def define_through_options
        private

        def source_type
          @relation_name.singularize.camelize
        end

        def source_key
          "#{@relation_name.singularize}_id".to_sym
        end

        define_source if @options[:source]
        define_source_type if @options[:source_type]
      end

      def define_source
        undef source_type
        undef source_key

        private

        def source_type
          @options[:source].to_s.camelize
        end

        def source_key
          "#{@options[:source].to_s.singularize}_id".to_sym
        end
      end

      def define_source_type
        undef source_type

        private

        def source_type
          @options[:source_type]
        end
      end

      def related_table
        @options[:through].to_s.camelize.singularize
      end
    end
  end
end