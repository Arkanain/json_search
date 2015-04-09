class Language < ORM::ActiveRecord
  scope :by_name, -> (name) { where(name: name) }
end