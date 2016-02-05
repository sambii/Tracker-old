class AddStudentGradeLevelToEnrollment < ActiveRecord::Migration
  def self.up
    add_column :enrollments, :student_grade_level, :integer
  end

  def self.down
    remove_column :enrollments, :student_grade_level
  end
end
