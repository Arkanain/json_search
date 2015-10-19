module ORM
  module Associations
    class HasOne < SingularAssociation
      class << self
        attr_reader :relation_name, :options, :current_object, :relation_hash

        def has_one(current_object, relation_name, options={})
          @relation_name = relation_name.to_s
          @options = options
          @current_object = current_object

          if @options[:source] && (@options[:source].to_s == @options[:source].to_s.pluralize)
            raise ORM::ModelError, ":source option for relation has_many :#{@relation_name} in #{@current_object} model should have singular name"
          end

          if @options[:source_type] && !Object.const_defined?(@options[:source_type])
            raise ORM::ModelError, "Can't find class which is specified for :source_type option for relation has_many :#{@relation_name} in #{self} model"
          end

          #This hash is needed to pass params inside class eval and prevent problems with overload
          @relation_hash = {
            through: @options[:through].present?,
            foreign_key: foreign_key,
            primary_key: primary_key,
            order_key: order_key,
            class_name: class_name
          }

          if @options[:through].present?
            #If we have :through option then let's define special method for it
            define_through_options

            @relation_hash.merge!(
              source_type: source_type,
              source_key: source_key,
              related_table: related_table
            )

            #TODO ПЕРЕПИСЫВАЕМ СНАЧАЛА ЭТО
            @current_object.class_eval <<-CODE
              define_method("#{@relation_name}") do
                #{@options[:through]} = #{related_table}.where(#{foreign_key}: self.#{primary_key})

                #{source_type}.where(id: #{@options[:through]}.order(:#{order_key}).map(&:#{source_key}))
              end

              define_method("#{@relation_name}=") do |value|
                unless value.is_a?(#{source_type})
                  raise ORM::ModelError, "One of object which you try to assign is not a type of #{source_type}."
                end

                #{@options[:through]} = #{related_table}.where(#{foreign_key}: self.#{primary_key}).first

                if #{@options[:through]}.present?
                  #{@options[:through]}.#{source_key} = value.id
                else
                  #{related_table}.create(#{foreign_key}: self.#{primary_key}, #{source_key}: value.id)
                end
              end
            CODE
          else
            @current_object.class_eval <<-CODE
              define_method("#{@relation_name}") do
                ORM::Associations::CollectionProxy.new(self, #{relation_hash}).first
              end

              define_method("#{@relation_name}=") do |value|
                unless value.is_a?(#{class_name})
                  raise ORM::ModelError, "Objects which you try to assign is not a type of #{class_name}."
                end

                value.update_attribute(:#{foreign_key}, self.#{primary_key})
              end
            CODE
          end
        end

        def order_key
          @options[:order].present? ? @options[:order].to_sym : :id
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