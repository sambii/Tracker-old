class ChangeEnrollmentSubsectionToNotAllowNull < ActiveRecord::Migration
  def up
  	change_column :enrollments, :subsection, :integer, :null => false
  end

  def down
  	change_column :enrollments, :subsection, :integer, :null => true
  end
end
