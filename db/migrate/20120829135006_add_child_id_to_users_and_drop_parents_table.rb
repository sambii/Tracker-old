class AddChildIdToUsersAndDropParentsTable < ActiveRecord::Migration
  def change
    add_column :users, :child_id, :integer, default: 0
    drop_table :parents
  end
end
