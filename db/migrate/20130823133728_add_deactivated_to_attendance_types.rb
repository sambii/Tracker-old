class AddDeactivatedToAttendanceTypes < ActiveRecord::Migration
  def change
    add_column :attendance_types, :deactivated, :boolean, default: false
  end
end
