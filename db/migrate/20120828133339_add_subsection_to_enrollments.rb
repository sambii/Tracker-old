class AddSubsectionToEnrollments < ActiveRecord::Migration
  def change
    add_column :enrollments, :subsection, :integer, default: 0
  end
end
