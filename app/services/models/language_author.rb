class LanguageAuthor < ORM::ActiveRecord
  belongs_to :author
  belongs_to :language
end