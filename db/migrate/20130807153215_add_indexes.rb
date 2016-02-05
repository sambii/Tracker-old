class AddIndexes < ActiveRecord::Migration
  def up
    add_index :enrollments, :student_id
    add_index :enrollments, :section_id
    add_index :enrollments, :student_grade_level
    add_index :evidence_attachments, :evidence_id
    add_index :evidence_hyperlinks, :evidence_id
    add_index :evidence_ratings, :student_id
    add_index :evidence_ratings, :evidence_id
    add_index :evidence_section_outcome_ratings, :student_id
    add_index :evidence_section_outcome_ratings, :evidence_section_outcome_id, name: 'evidence_section_outcome_ratings_on_eso_id'
    add_index :evidence_section_outcomes, :evidence_id
    # add_index :evidence_section_outcomes, :section_outcome_id
    add_index :evidence_template_subject_outcomes, :evidence_template_id
    add_index :evidence_template_subject_outcomes, :subject_outcome_id
    add_index :evidence_templates, :subject_id
    # add_index :evidences, :section_outcome_id
    add_index :evidences, :evidence_type_id
    add_index :evidences, :section_id
    add_index :posts, :user_id
    add_index :posts, :parent_id
    add_index :posts, :top_level_post_id
    add_index :section_attachments, :section_id
    add_index :section_outcome_attachments, :section_outcome_id
    add_index :section_outcome_ratings, :student_id
    add_index :section_outcome_ratings, :section_outcome_id
    add_index :section_outcomes, :section_id
    add_index :section_outcomes, :subject_outcome_id
    add_index :section_outcomes, :marking_period
    add_index :sections, :subject_id
    add_index :sections, :school_year_id
    add_index :subject_outcomes, :subject_id
    add_index :subjects, :discipline_id
    add_index :subjects, :school_id
    add_index :subjects, :subject_manager_id
    add_index :teaching_assignments, :teacher_id
    add_index :teaching_assignments, :section_id
    add_index :teaching_resources, :discipline_id
    # add_index :users, :username
    add_index :users, :school_id
    add_index :users, [:school_id, :grade_level]
    add_index :users, [:school_id, :counselor]
    add_index :users, [:school_id, :school_administrator]
    add_index :users, [:school_id, :student]
    add_index :users, [:school_id, :system_administrator]
    add_index :users, [:school_id, :teacher]
    add_index :users, [:school_id, :xid]
    add_index :users, [:school_id, :child_id]
    add_index :users, [:school_id, :parent]
    add_index :users, [:school_id, :researcher]
    add_index :users, [:school_id, :special_ed]
  end

  def down
    remove_index :enrollments, column: :student_id
    remove_index :enrollments, column: :section_id
    remove_index :enrollments, column: :student_grade_level
    remove_index :evidence_attachments, column: :evidence_id
    remove_index :evidence_hyperlinks, column: :evidence_id
    remove_index :evidence_ratings, column: :student_id
    remove_index :evidence_ratings, column: :evidence_id
    remove_index :evidence_section_outcome_ratings, column: :student_id
    remove_index :evidence_section_outcome_ratings, name: 'evidence_section_outcome_ratings_on_eso_id'
    remove_index :evidence_section_outcomes, column: :evidence_id
    # remove_index :evidence_section_outcomes, column: :section_outcome_id
    remove_index :evidence_template_subject_outcomes, column: :evidence_template_id
    remove_index :evidence_template_subject_outcomes, column: :subject_outcome_id
    remove_index :evidence_templates, column: :subject_id
    # remove_index :evidences, column: :section_outcome_id
    remove_index :evidences, column: :evidence_type_id
    remove_index :evidences, column: :section_id
    remove_index :posts, column: :user_id
    remove_index :posts, column: :parent_id
    remove_index :posts, column: :top_level_post_id
    remove_index :section_attachments, column: :section_id
    remove_index :section_outcome_attachments, column: :section_outcome_id
    remove_index :section_outcome_ratings, column: :student_id
    remove_index :section_outcome_ratings, column: :section_outcome_id
    remove_index :section_outcomes, column: :section_id
    remove_index :section_outcomes, column: :subject_outcome_id
    remove_index :section_outcomes, column: :marking_period
    remove_index :sections, column: :subject_id
    remove_index :sections, column: :school_year_id
    remove_index :subject_outcomes, column: :subject_id
    remove_index :subjects, column: :discipline_id
    remove_index :subjects, column: :school_id
    remove_index :subjects, column: :subject_manager_id
    remove_index :teaching_assignments, column: :teacher_id
    remove_index :teaching_assignments, column: :section_id
    remove_index :teaching_resources, column: :discipline_id
    # remove_index :users, column: :username
    remove_index :users, column: :school_id
    remove_index :users, column: [:school_id, :grade_level]
    remove_index :users, column: [:school_id, :counselor]
    remove_index :users, column: [:school_id, :school_administrator]
    remove_index :users, column: [:school_id, :student]
    remove_index :users, column: [:school_id, :system_administrator]
    remove_index :users, column: [:school_id, :teacher]
    remove_index :users, column: [:school_id, :xid]
    remove_index :users, column: [:school_id, :child_id]
    remove_index :users, column: [:school_id, :parent]
    remove_index :users, column: [:school_id, :researcher]
    remove_index :users, column: [:school_id, :special_ed]
  end
end
