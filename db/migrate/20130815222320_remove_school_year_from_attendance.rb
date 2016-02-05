class RemoveSchoolYearFromAttendance < ActiveRecord::Migration
  def up
    remove_column :attendances, :school_year_id
  end
  def down
    add_column :attendances, :school_year_id, :integer
    add_index :attendances, :school_year_id
  end
end
