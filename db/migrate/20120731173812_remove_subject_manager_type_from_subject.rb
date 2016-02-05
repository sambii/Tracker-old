class RemoveSubjectManagerTypeFromSubject < ActiveRecord::Migration
  def up
    remove_column :subjects, :subject_manager_type
  end

  def down
    add_column :subjects, :subject_manager_type, :string
  end
end
