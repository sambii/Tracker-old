class AddSchoolIdAndGradeLevelAndGenderToUsers < ActiveRecord::Migration
  def change
    add_column :users, :school_id, :integer
    add_column :users, :grade_level, :integer
    add_column :users, :gender, :string
  end
end
