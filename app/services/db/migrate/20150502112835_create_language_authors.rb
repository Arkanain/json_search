class CreateLanguageAuthors < ORM::Migration
  def up
    create_table :language_authors do |t|
      t.integer :language_id
      t.integer :author_id

      t.timestamps
    end
  end

  def down
    drop_table :language_authors
  end
end