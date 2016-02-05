class RemoveSubjectIdFromAttendance < ActiveRecord::Migration
  def up
    remove_column :attendances, :subject_id
  end

  def down
    add_column :attendances, :subject_id, :integer
    add_index :attendances, :subject_id
  end
end
