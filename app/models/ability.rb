# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class Ability
  include CanCan::Ability

  def initialize(user, session)
    user ||= User.new

    can :hide, Announcement

    # default cannot create any user types, unless specifically allowed by user role.
    cannot [:create, :read, :update, :dashboard, :security], User

    if user.active?


      #########################################################################
      if user.parent?
        # Enrollment
        can [:show],
          Enrollment,
          { student_id: user.child_id }

        # Student
        can [:show],
          Student,
          { id: user.child_id }

        # User (Self)
        can [:read, :change_password, :edit, :update, :profile],
          User,
          { id: user.id }

        # parents cannot update their password in the model school (for student orientation use)
        cannot [:update],
            User,
            { id: user.id, school_id: 1}

        # cannot Generate Reports
        cannot [:read], Generate

      end


      #########################################################################
      if user.student?
        # Enrollment
        can [:show],
          Enrollment,
          { student_id: user.id }

        # Student (Self)
        can [:show],
            Student,
            { id: user.id }

        # User (Self)
        can [:read, :change_password, :edit, :update, :profile],
            User,
            { id: user.id }

        # students cannot update their password in the model school (for student orientation use)
        cannot [:update],
            User,
            { id: user.id, school_id: 1}

        # cannot Generate Reports
        cannot [:read], Generate

       end


      #########################################################################
      if user.counselor?
        # Enrollment
        can [:show],
            Enrollment,
            { student: {school_id: user.school_id } }

        # Evidence
        can [:show_attachments],
            Evidence,
          { school_id: user.school_id }

        # Student
        if user.school_id
          can [:read, :proficiency_bars],
            Student,
            { id: user.counselor.school.students.pluck(:id) }
        end

        # Subject
        can [:read, :proficiency_bars],
            Subject,
            { school_id: user.school_id }

        # User (Self)
        can [:read, :change_password, :edit, :update, :profile],
            User,
            { id: user.id }

        # Attendance
        can :read,
          [ Attendance, Excuse, AttendanceType ],
          { school_id: user.school_id }

        can :manage, Generate

      end


      #########################################################################
      if user.teacher?
        # Enrollment
        can [:show, :create, :update],
            Enrollment,
            { section_id: user.teacher.teaching_assignments.pluck(:section_id) }

        # Evidence
        can [:create, :rate, :show, :update, :show_attachments],
            Evidence,
            { section_id: user.teacher.teaching_assignments.pluck(:section_id) }
        can [:new, :create], Evidence # added this for creation of new evidences (where record has no sections yet)

        # EvidenceSectionOutcome
        can [:show, :sort, :update],
            EvidenceSectionOutcome,
            { section_outcome_id: user.teacher.section_outcomes.pluck(:id) }

        # EvidenceSectionOutcomeRating
        can [:create, :show, :update],
            EvidenceSectionOutcomeRating,
            { evidence_section_outcome: { section_outcome: { section_id: user.teacher.teaching_assignments.pluck(:section_id) } } }

        # School
        can [:read],
            School,
            { id: user.school_id }

        # Section
        can [:create, :new_enrollment, :new_evidence, :new_section_outcome,
             :section_outcomes, :show, :sort, :update, :restore_evidence, :section_summary_outcome, :section_summary_student, :nyp_student, :nyp_outcome, :student_info_handout, :progress_rpt_gen, :class_dashboard, :edit_section_message, :exp_col_all_evid, :list_enrollments, :remove_enrollment],
            Section,
            { teaching_assignments: {teacher_id: user.id }}
        can [:new, :create], Section # added this for creation of new sections (where record has no subject yet)

        # SectionOutcome
        can [:create, :show, :sort, :update, :evidences_left, :evidences_right, :toggle_marking_period],
            SectionOutcome,
            {section_id: user.teacher.teaching_assignments.pluck(:section_id) }

        # SectionOutcomeRating
        can [:create, :update],
            SectionOutcomeRating,
            { section_outcome_id: user.teacher.section_outcomes.pluck(:id) }

        # Student
        can [:create, :read, :update, :dashboard, :security],
            [Student, Parent],
            {school_id: user.school_id }

        # Subject
        can [:read],
            Subject,
            { school_id: user.school_id }
        can [:edit_subject_outcomes, :update_subject_outcomes],
            Subject,
            { subject_manager_id: user.id }

        # Teacher
        can [:read],
            Teacher,
            { id: user.id }

        # User
        can [:read, :change_password, :edit, :update, :profile],
            User,
            { id: user.id }

        can [:create, :update, :dashboard, :security, :set_temporary_password], ["system_administrator = 1 or researcher = 1 or school_administrator = 1 or counselor = 1"], User do |u|
          reject = false
          u.role_symbols.each do |r|
            reject = true if ![:student, :parent].include?(r)
          end
          u.school_id == user.school_id and !reject
        end

        # Attendance
        can :manage,
          Attendance,
          { school_id: user.school_id, section_id: user.teacher.teaching_assignments.pluck(:section_id) }
        can :read,
          [ Excuse, AttendanceType ],
          { school_id: user.school_id }

        can :manage, Generate
      end


      #########################################################################
      if user.researcher?
        can :read, :all

        can :manage, Generate
        can :create, ReportCardRequest
        can [:section_summary_outcome, :section_summary_student, :nyp_outcome, :nyp_student, :student_info_handout, :student_info_handout_by_grade, :progress_rpt_gen, :class_dashboard], Section
        can :switch, School
        can :proficiency_bars, Student
        can [:proficiency_bars, :progress_meters], Subject
        can [:staff_listing, :account_activity_report], User

        cannot [:edit], User
        cannot [:edit], Student
        can [:read, :change_password, :edit, :update, :profile],
          User,
          { id: user.id }
      end


      #########################################################################
      if user.school_administrator?
        # Enrollment
        can [:show, :create, :update, :enter_bulk, :update_bulk],
          Enrollment,
          { student: {school_id: user.school_id } }

        # Evidence
        can [:create, :rate, :show, :update, :show_attachments],
          Evidence,
          { section: { subject: { school_id: user.school_id } } }
        can [:new, :create], Evidence # added this for creation of new evidences (where record has no sections yet)

        # EvidenceSectionOutcomeRating
        can [:create, :show, :update],
          EvidenceSectionOutcomeRating,
          { evidence_section_outcome: { section_outcome: { section: { subject: { school_id: user.school_id } } } } }

        # School
        can [:read, :edit, :update],
          School,
          { id: user.school_id }

        # Section
        can [:create, :index, :new_enrollment, :new_evidence, :new_section_outcome,
             :section_outcomes, :show, :sort, :update, :restore_evidence, :section_summary_outcome, :section_summary_student, :nyp_student, :nyp_outcome, :student_info_handout, :student_info_handout_by_grade, :progress_rpt_gen, :class_dashboard, :edit_section_message, :exp_col_all_evid, :list_enrollments, :remove_enrollment, :enter_bulk, :update_bulk],
          Section,
          { subject: {school_id: user.school_id }}
        can [:new, :create], Section # added this for creation of new sections (where record has no subject yet)

        # SectionOutcome
        can [:create, :show, :sort, :update, :evidences_left, :evidences_right, :toggle_marking_period],
            SectionOutcome,
            { section: { subject: { school_id: user.school_id } } }

        # SubjectOutcome
        can [:create, :show, :update],
            SubjectOutcome,
            { subject: { school_id: user.school_id } }

        # SectionOutcomeRating
        can [:create, :update],
          SectionOutcomeRating,
          { section_outcome: { section: { subject: { school_id: user.school_id } } } }

        # Student
        can [:create, :deactivate, :read, :update, :dashboard, :security, :proficiency_bars, :bulk_upload, :bulk_update],
          Student,
          { school_id: user.school_id }

        # Subject
        can [:read],
            Subject,
            { school_id: user.school_id }

        can [:proficiency_bars, :progress_meters],
            Subject,
            { school_id: user.school_id }

        # Teacher
        can [:read, :create, :update, :dashboard],
          Teacher,
          { school_id: user.school_id }

        can [:enter_bulk, :update_bulk],
          TeachingAssignment,
          {teacher: {school_id: user.school_id}}

        # User
        can [:create, :read, :update, :set_temporary_password, :account_activity_report, :staff_listing, :dashboard, :security, :new_staff, :create_staff, :profile, :sections_list, :bulk_upload_staff, :bulk_update_staff],
          User,
          { school_id: user.school_id }

        can [:read, :change_password, :edit, :update, :profile],
          User,
          { id: user.id }

        # Report Card Request
        can [:create, :forward],
          ReportCardRequest

        # Attendance
        can :manage,
          Attendance,
          { school_id: user.school_id }
        can :manage,
          [ Excuse, AttendanceType ],
          { school_id: user.school_id }

        can :manage, Generate

        can :upload_bulk_templates, Misc
      end


      #########################################################################
      # permission based abilities:
      # note school authorization must be done elsewhere
      if user.has_permission?('subject_admin')
        can [:read, :create, :update, :subject_admin, :edit_subject_outcomes, :update_subject_outcomes],
        Subject
      end


      #########################################################################
      # added last, so this system admin role's rights overrides all others above
      if user.system_administrator? # and session[:school_context].to_i == 0
        can :manage, :all
      end

    end
  end

  def readable? user, other_user, school_id
    unless (other_user.id == user.id) || (other_user.school_id == school_id)
      raise CanCan::AccessDenied.new("Unable to manage this user!", :read, User)
    end
    return true
  end

end
