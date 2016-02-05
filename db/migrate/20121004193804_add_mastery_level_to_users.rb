class AddMasteryLevelToUsers < ActiveRecord::Migration
  def change
    add_column :users, :mastery_level, :string
  end
end
