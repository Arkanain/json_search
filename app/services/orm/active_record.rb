module ORM
  class ActiveRecord
    extend Associations
    extend ClassQuerying

    include InstanceQuerying
  end
end

#TODO:
# 1) implement validation functionality

#TODO: I will need this for validation
# :string && :text = String = "string"
# :integer = Integer = "integer"
# :float = Float = "float"
# :decimal = BigDecimal = "decimal"
# :datetime && :timestamp && :time && :date = DateTime = "datetime"
# :boolean = FalseClass || TrueClass = "boolean"