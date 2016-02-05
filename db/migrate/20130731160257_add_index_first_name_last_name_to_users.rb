class AddIndexFirstNameLastNameToUsers < ActiveRecord::Migration
  def change
  	add_index :users, [:last_name, :first_name]
  end
end
