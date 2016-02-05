class RemoveStudentsCounselorsSchoolAdministratorsSystemAdministratorsAndRoles < ActiveRecord::Migration
  def up
    drop_table :counselors
    drop_table :school_administrators
    drop_table :teachers
    drop_table :roles
  end

  def down
  end
end
