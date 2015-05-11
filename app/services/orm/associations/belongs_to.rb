module ORM
  module Associations
    class BelongsTo < SingularAssociation
      class << self
        def belongs_to(current_object, relation_name, options={})
          @relation_name = relation_name.to_s
          @options = options
          @current_object = current_object

          @current_object.relations.module_eval <<-CODE
            define_method("#{@relation_name}") do
              #{class_name}.where(#{primary_key}: self.#{foreign_key}).first
            end

            define_method("#{@relation_name}=") do |value|
              unless value.is_a?(#{class_name})
                raise ORM::ModelError, "Objects which you try to assign is not a type of #{class_name}."
              end

              self.update_attribute(:#{foreign_key}, value.id)
            end
          CODE
        end

        #def polymorphic
        #
        #end

        #def dependent
        #
        #end

        #def foreign_type
        #
        #end

        def foreign_key
          "#{@relation_name}_id".to_sym
        end
      end
    end
  end
end