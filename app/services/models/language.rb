class Language < ORM::ActiveRecord
  #scope :by_name, -> (name) { where(name: name) }

  #has_many :authors

  has_many :language_authors
  has_many :authors, through: :language_authors

  #has_many :language_authors
  #has_many :authors, through: :language_authors, source: :author, source_type: 'Author'

  #has_many :language_authors
  #has_many :authors, through: :language_authors
end