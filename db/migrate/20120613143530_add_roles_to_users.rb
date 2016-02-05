class AddRolesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :counselor, :boolean
    add_column :users, :school_administrator, :boolean
    add_column :users, :student, :boolean
    add_column :users, :system_administrator, :boolean
    add_column :users, :teacher, :boolean
  end
end
