class Author < ORM::ActiveRecord
  has_many :language_authors
  has_many :languages, through: :language_authors
end