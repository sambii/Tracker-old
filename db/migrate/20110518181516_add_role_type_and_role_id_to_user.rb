class AddRoleTypeAndRoleIdToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :role_type, :string
    add_column :users, :role_id, :integer
  end

  def self.down
    remove_column :users, :role_id
    remove_column :users, :role_type
  end
end
