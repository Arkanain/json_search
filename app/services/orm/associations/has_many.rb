module ORM
  module Associations
    class HasMany < CollectionAssociation
      class << self
        attr_reader :relation_name, :options, :current_object

        def has_many(current_object, relation_name, options={})
          @relation_name = relation_name.to_s
          @options = options
          @current_object = current_object

          if @options[:source] && (@options[:source].to_s == @options[:source].to_s.pluralize)
            raise ORM::ModelError, ":source option for relation has_many :#{@relation_name} in #{@current_object} model should have singular name"
          end

          if @options[:source_type] && !Object.const_defined?(@options[:source_type])
            raise ORM::ModelError, "Can't find class which is specified for :source_type option for relation has_many :#{@relation_name} in #{self} model"
          end

          if @options[:through].present?
            #If we have :through option then let's define special method for it
            define_through_options

            @current_object.relations.module_eval <<-CODE
              define_method("#{@relation_name}") do
                #{@options[:through]} = #{related_table}.where(#{foreign_key}: self.#{primary_key})

                #{source_type}.where(id: #{@options[:through]}.order(:#{order_key}).map(&:#{source_key}))
              end

              define_method("#{@relation_name}=") do |values|
                values = [values] unless values.is_a?(Array)

                values.each do |value|
                  unless value.is_a?(#{source_type})
                    raise ORM::ModelError, "One of object which you try to assign is not a type of #{source_type}."
                  end
                end

                #{@options[:through]} = #{related_table}.where(#{foreign_key}: self.#{primary_key}).map(&:#{source_key})

                new_rows = values.map(&:id) - #{@options[:through]}
                new_rows.each do |row_id|
                  #{related_table}.create(#{foreign_key}: self.#{primary_key}, #{source_key}: row_id)
                end
              end
            CODE
          else
            @current_object.relations.module_eval <<-CODE
              define_method("#{@relation_name}") do
                ORM::Associations::CollectionProxy.new(self, #{self})
              end

              define_method("#{@relation_name}=") do |values|
                ORM::Associations::CollectionProxy.new(self, #{self}).each do |row|
                  row.update_attribute(:#{foreign_key}, nil)
                end

                values.each do |row|
                  unless row.is_a?(#{class_name})
                    raise ORM::ModelError, "One of objects which you try to assign is not a type of #{class_name}."
                  end

                  row.update_attribute(:#{foreign_key}, self.#{primary_key})
                end
              end
            CODE
          end
        end

        #{class_name}.where(#{foreign_key}: self.#{primary_key}).order(:#{order_key})

        #def dependent
        #
        #end

        def order_key
          @options[:order].present? ? @options[:order].to_sym : :id
        end

        def foreign_key
          "#{@current_object.name.underscore}_id".to_sym
        end

        def primary_key
          @options[:primary_key].present? ? @options[:primary_key].to_sym : :id
        end

        def related_table
          @options[:through].to_s.camelize.singularize
        end

        def define_through_options
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

          def source_type
            @options[:source].to_s.camelize
          end

          def source_key
            "#{@options[:source].to_s.singularize}_id".to_sym
          end
        end

        def define_source_type
          undef source_type

          def source_type
            @options[:source_type]
          end
        end
      end
    end
  end
end