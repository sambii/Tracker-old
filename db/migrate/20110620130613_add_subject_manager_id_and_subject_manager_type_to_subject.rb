class AddSubjectManagerIdAndSubjectManagerTypeToSubject < ActiveRecord::Migration
  def self.up
    add_column :subjects, :subject_manager_id, :integer
    add_column :subjects, :subject_manager_type, :string
  end

  def self.down
    remove_column :subjects, :subject_manager_type
    remove_column :subjects, :subject_manager_id
  end
end
