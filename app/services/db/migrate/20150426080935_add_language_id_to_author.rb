class AddLanguageIdToAuthor < ORM::Migration
  def up
    add_column :authors, :language_id, :integer
  end

  def down
    remove_column :authors, :language_id
  end
end