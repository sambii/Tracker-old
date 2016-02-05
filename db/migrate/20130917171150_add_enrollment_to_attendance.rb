class AddEnrollmentToAttendance < ActiveRecord::Migration
  def change
    add_column :attendances, :enrollment_id, :integer
    add_index :attendances, :enrollment_id
  end
end
