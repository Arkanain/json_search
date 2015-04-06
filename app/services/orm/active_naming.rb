module ORM
  class ActiveNaming
    attr_reader :collection, :element, :human, :klass, :name, :param_key, :plural, :route_key, :singular, :singular_route_key

    def initialize(base)
      @klass = base
      @singular = base.name.downcase.singularize
      @plural = base.name.downcase.pluralize
      @element = base.name.downcase.underscore
      @human = base.name.humanize
      @collection = base.name.tableize
      @param_key = base.name.downcase.singularize
      @route_key = base.name.downcase.pluralize
      @singular_route_key = base.name.downcase.singularize
      @name = base.name
    end
  end
end