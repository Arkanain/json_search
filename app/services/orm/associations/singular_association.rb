module ORM
  module Associations
    class SingularAssociation < Association
      class << self
        #TODO: implement this methods later when I will understand what they do
        #def remote
        #
        #end

        #def dependent
        #
        #end

        def primary_key
          @options[:primary_key].present? ? @options[:primary_key].to_sym : :id
        end
      end
    end
  end
end