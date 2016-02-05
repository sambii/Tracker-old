class AddAbsencesAndTardiesAndAttendanceRateToUsers < ActiveRecord::Migration
  def change
    add_column :users, :absences, :integer
    add_column :users, :tardies, :integer
    add_column :users, :attendance_rate, :integer
  end
end
