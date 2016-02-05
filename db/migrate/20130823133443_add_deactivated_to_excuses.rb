class AddDeactivatedToExcuses < ActiveRecord::Migration
  def change
    add_column :excuses, :deactivated, :boolean, default: false
  end
end