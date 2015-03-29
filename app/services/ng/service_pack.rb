module Ng
  module ServicePack
    def self.included(base)
      before_methods
    end

    def self.before_methods
      (Array.instance_methods - Object.instance_methods).each do |name|
        define_method(name) do |*args, &block|
          to_a.send(name, *args, &block)
        end
      end
    end
  end
end