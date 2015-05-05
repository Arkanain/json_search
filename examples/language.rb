class Language < ORM::ActiveRecord
  has_many :language_authors
  has_many :authors, through: :language_authors, source: :author, source_type: 'Author'

  scope :by_name, -> (name) { where(name: name) }
end