class RemoveEnrollmentIdFromAttendance < ActiveRecord::Migration
  def up
    remove_column :attendances, :enrollment_id
    # remove_index :attendances, :enrollment_id   # index is removed automatically
  end

  def down
    add_column :attendances, :enrollment_id, :integer
    add_index :attendances, :enrollment_id
  end
end
