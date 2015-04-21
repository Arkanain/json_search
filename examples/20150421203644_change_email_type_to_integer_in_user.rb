class ChangeEmailTypeToIntegerInUser < ORM::Migration
  def up
    change_column :users, :email, :integer
  end

  def down
    change_column :users, :email, :string
  end
end