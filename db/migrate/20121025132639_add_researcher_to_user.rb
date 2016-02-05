class AddResearcherToUser < ActiveRecord::Migration
  def change
    add_column :users, :researcher, :boolean, default: false
  end
end
