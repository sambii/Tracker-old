class DeactivatedToActive < ActiveRecord::Migration
  def up
    remove_column :attendance_types, :deactivated
    remove_column :excuses, :deactivated
    add_column :attendance_types, :active, :boolean, default: true
    add_column :excuses, :active, :boolean, default: true
  end

  def down
    add_column :attendance_types, :deactivated, :boolean, default: false
    add_column :excuses, :deactivated, :boolean, default: false
    remove_column :attendance_types, :active
    remove_column :excuses, :active
  end
end
