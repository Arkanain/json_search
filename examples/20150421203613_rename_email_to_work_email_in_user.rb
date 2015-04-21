class RenameEmailToWorkEmailInUser < ORM::Migration
  def up
    rename_column :users, :email, :work_email
  end

  def down
    rename_column :users, :work_email, :email
  end
end