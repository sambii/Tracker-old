class AddSubscriptionStatusToUsers < ActiveRecord::Migration
  def change
    add_column :users, :subscription_status, :string
  end
end
