class AddSchoolToAttendanceTypes < ActiveRecord::Migration
  def change
    add_column :attendance_types, :school_id, :integer
    add_index :attendance_types, :school_id
  end
end
