module ORM
  module ActiveRel
    include Support::ServicePack

    attr_accessor :collection, :type

    def initialize(type, obj)
      self.type = type
      self.collection = obj

      self.class.include self.type.scopes if self.type.scopes.present?
    end

    def where(hash)
      type.where(hash, collection)
    end

    def matches(string, fields)
      type.matches(string, fields, collection)
    end

    private

    def to_a
      type.objects_array(collection)
    end
  end
end