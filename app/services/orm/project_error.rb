module ORM
  class ActiveRecordError < StandardError
  end

  class DBError < StandardError
  end

  class TableError < StandardError
  end

  class ModelError < StandardError
  end
end