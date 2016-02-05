class ChangeAttendanceDateType < ActiveRecord::Migration
  def up
    change_column :attendances, :attendance_date, :date
  end

  def down
    change_column :attendances, :attendance_date, :datetime
  end
end
