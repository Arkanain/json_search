module ORM
  module Associations
    include HasMany
    #include HasOne
    #include BelongsTo

    instance_methods.each do |method_name|
      private method_name
    end
  end
end