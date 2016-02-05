class Indexing2 < ActiveRecord::Migration
  def up
    add_index :announcements, :start_at # per announcement.rb
    add_index :announcements, :end_at # per announcement.rb
    add_index :announcements, :restrict_to_staff # per announcement.rb
    add_index :disciplines, :name # per discipline.rb (include_teaching_resources scope)
    remove_index :enrollments, :student_grade_level # not needed
    add_index :enrollments, :subsection # per section.rb (active_students scope)
    add_index :enrollments, :active # per section.rb (active_students scope), enrollment.rb (alphabetical scope)
    # optionally replace these two with just section_id and active
    add_index :enrollments, [:section_id, :active, :student_id], name: 'enrollments_multi' # for evidences_controller.rb (rate method)
    add_index :enrollments, [:section_id, :active, :subsection], name: 'enrollments_multi2' # section.rb (active_students scope)
    add_index :enrollments, [:section_id, :active], name: 'enrollments_multi3' # section.rb (active_students no subsection scope)
    add_index :enrollments, [:section_id, :subsection], name: 'enrollments_multi4' # section.rb (subsections scope)  todo - see if we can add active to where clause and use index above
    add_index :evidence_section_outcome_ratings, [:evidence_section_outcome_id, :student_id], name: 'evidence_section_outcome_ratings_multi' # per evidence_section_outcome_rating.rb (uniquify validation and validates uniqueness
    # ?? todo - possible duplication of validation in evidence_section_outcome_rating.rb. see also section_outcome_ratings)
    add_index :evidence_section_outcomes, :section_outcome_id # fk index for joins
    add_index :evidence_section_outcomes, :position # per section.rb (data_array ?experimental? method)
    add_index :evidences, [:active, :position], name: 'evidences_multi' # per section (:active_evidences) - also only active for  section_outcome.rb (evidence_section_outcomes join), section (:inactive_evidences)
    add_index :school_years, :school_id # fk index for joins
    add_index :schools, :school_year_id # fk index for joins, and per section (old and current scopes), enrollment (old and current scopes)
    add_index :section_outcome_ratings, [:student_id, :section_outcome_id], name: 'section_outcome_ratings_multi' # per section_outcome_rating.rb (uniquify validation and validates_uniqueness_of student_id 
    # ?? todo - look into section_outcome_rating.rb for possible double validation and cleanup ??)
    remove_index :section_outcomes, :marking_period # not needed
    add_index :section_outcomes, :active # per  student.rb (active_section_outcome_ratings scope)
    add_index :section_outcomes, :position # per  section.rb (active_section_outcome_ratings scope)
    add_index :section_outcomes, [:section_id, :active, :position], name: 'section_outcomes_multi' # per  section.rb (section_outcomes join, evidences join) and teacher.rb
    add_index :subject_outcomes, [:subject_id, :name], name: 'subject_outcomes_multi' # per subject_outcomes.rb (validates_uniqueness_of :name)
    add_index :teaching_assignments, [:teacher_id, :section_id], name: 'teaching_assignments_multi'  # per ability.rb (teacher enrollments)
    add_index :teaching_resources, :title # per teaching_resource.rb (by_discipline scopes), discipline.rb (include_teaching_resources scope)
    add_index :users, :active # section.rb (enrollments join)
    add_index :users, :subscription_status # parent.rb (send_emails method)
    add_index :users, [:teacher, :active, :last_name, :first_name], name: 'teacher_alphabetical' # teacher.rb (default where and order scopes)
    add_index :users, [:student, :active, :last_name, :first_name], name: 'student_alphabetical' # enrollment.rb (alphabetical scope)


  end

  def down
    remove_index :announcements, :start_at
    remove_index :announcements, :end_at
    remove_index :announcements, :restrict_to_staff
    remove_index :disciplines, :name
    add_index :enrollments, :student_grade_level
    remove_index :enrollments, :subsection
    remove_index :enrollments, :active
    remove_index :enrollments, name: :enrollments_multi
    remove_index :enrollments, name: :enrollments_multi2
    remove_index :enrollments, name: :enrollments_multi3
    remove_index :enrollments, name: :enrollments_multi4
    remove_index :evidence_section_outcome_ratings, name: :evidence_section_outcome_ratings_multi
    remove_index :evidence_section_outcomes, :section_outcome_id
    remove_index :evidence_section_outcomes, :position
    remove_index :evidences, name: :evidences_multi
    remove_index :school_years, :school_id
    remove_index :schools, :school_year_id
    remove_index :section_outcome_ratings, name: :section_outcome_ratings_multi
    add_index :section_outcomes, :marking_period
    remove_index :section_outcomes, :active
    remove_index :section_outcomes, :position
    remove_index :section_outcomes, name: :section_outcomes_multi
    remove_index :subject_outcomes, name: :subject_outcomes_multi
    remove_index :teaching_assignments, name: :teaching_assignments_multi
    remove_index :teaching_resources, :title
    remove_index :users, :active
    remove_index :users, :subscription_status
    remove_index :users, name: :teacher_alphabetical
    remove_index :users, name: :student_alphabetical
  end
end
