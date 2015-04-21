module ORM
  class ActiveRecordError < StandardError
  end

  class DBError < StandardError
  end

  class TableError < DBError
  end

  class ModelError < ActiveRecordError
  end

  class FieldTypeError < DBError
  end
end