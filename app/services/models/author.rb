class Author < ORM::ActiveRecord
  #belongs_to :language

  has_many :language_authors
  has_many :languages, through: :language_authors

  #has_many :language_authors
  #has_many :languages, through: :language_authors, order: :name

  #has_one :language_author
  #has_one :language, through: :language_author
end