class ManyToManyRolesImplementationPart2 < ActiveRecord::Migration
  def self.up
    remove_column       :users, :role_type
    remove_column       :users, :role_id
  end

  def self.down
    add_column          :users, :role_type, :string 
    add_column          :users, :role_id,   :integer
  end
end
