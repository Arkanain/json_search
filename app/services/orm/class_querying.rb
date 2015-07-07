module ORM
  module ClassQuerying
    #This attr accessor need for scopes which is declared in a class
    attr_accessor :scopes

    def all
      self::ActiveRelation.new(self)
    end

    def first
      all.first
    end

    def last
      all.last
    end

    def find(id)
      self::ActiveRelation.new(self).find(id)
    end

    def where(hash)
      self::ActiveRelation.new(self).where(hash)
    end

    def matches(string, fields)
      self::ActiveRelation.new(self).matches(string, fields)
    end

    def create(hash)
      new(hash).save
    end

    def scope(name, lambda)
      # Initialize empty module as a contianer for scope functions.
      self.scopes ||= Module.new

      self.scopes.module_eval do
        define_method(name.to_sym, &lambda)
      end
    end
  end
end