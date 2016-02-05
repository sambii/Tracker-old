class TeachingAssignmentChangeColumnNameFromSubjectIdToSectionId < ActiveRecord::Migration
  def self.up
    remove_column   :teaching_assignments, :subject_id
    add_column      :teaching_assignments, :section_id,   :integer
    add_column      :teaching_assignments, :write_access, :boolean, :default => true
    remove_column   :sections,             :teacher_id
  end

  def self.down
    add_column      :sections,             :teacher_id,   :integer
    add_column      :teaching_assignments, :subject_id,   :integer
    remove_column   :teaching_assignments, :section_id
    remove_column   :teaching_assignments, :write_access
  end
end
