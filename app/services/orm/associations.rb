module ORM
  module Associations
    attr_accessor :relations

    def has_many(relation_name, options={})
      ORM::Associations::HasMany.has_many(self, relation_name, options)
    end

    def has_one(relation_name, options={})
      self.relations ||= Module.new
      ORM::Associations::HasOne.has_one(self, relation_name, options)
    end

    def belongs_to(relation_name, options={})
      self.relations ||= Module.new
      ORM::Associations::BelongsTo.belongs_to(self, relation_name, options)
    end
  end
end