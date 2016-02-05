class CreateTeachingAssignments < ActiveRecord::Migration
  def self.up
    create_table :teaching_assignments do |t|
      t.integer :teacher_id
      t.integer :subject_id

      t.timestamps
    end
  end

  def self.down
    drop_table :teaching_assignments
  end
end
