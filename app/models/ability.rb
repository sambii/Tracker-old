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

        # student listing
        cannot [:index], Student

        # User (Self)
        can [:read, :change_password, :update, :profile],
          User,
          { id: user.id }
        cannot [:edit], User, {id: user.id}

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

        # student listing
        cannot [:index], Student

        # Student (Self)
        can [:show],
            Student,
            { id: user.id }

        # User (Self)
        can [:read, :change_password, :update, :profile],
            User,
            { id: user.id }
        cannot [:edit], User, {id: user.id}

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

        # Section
        can [:section_outcomes, :section_attendance],
          Section,
          { subject: { school_id: user.school_id } }

        # Student
        if user.school_id
          can [:read, :proficiency_bars],
            Student,
            { id: user.counselor.school.students.pluck(:id) }
        end

        # Subject
        can [:read, :proficiency_bars, :view_subject_outcomes],
            Subject,
            { school_id: user.school_id }

        # User (Self)
        can [:read, :change_password, :edit, :update, :profile],
            User,
            { id: user.id }

        # User
        can [:staff_listing, :dashboard],
          User,
          { school_id: user.school_id }

        # Attendance
        can [:student_attendance_detail_report, :attendance_report], Attendance
        can [:read],
          Attendance,
          { school_id: user.school_id, section_id: user.teacher.teaching_assignments.pluck(:section_id) }
        can :read,
          [ Excuse, AttendanceType ],
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
             :section_outcomes, :show, :sort, :update, :restore_evidence, :section_summary_outcome, :section_summary_student, :nyp_student, :nyp_outcome, :student_info_handout, :progress_rpt_gen, :class_dashboard, :edit_section_message, :exp_col_all_evid, :list_enrollments, :remove_enrollment, :section_outcomes, :index, :section_attendance],
            Section,
            { teaching_assignments: {teacher_id: user.id }}
        # teachers can create new sections in their school for any subject
        can [:new, :create], Section,
            { subject: { subject_manager_id: user.id }}
        # all teachers can see all section outcomes for their school (same as subject outcomes)
        can [:section_outcomes],
            Section,
            { subject: { school_id: user.school_id } }

        # SectionOutcome
        can [:create, :show, :sort, :update, :evidences_left, :evidences_right, :toggle_marking_period],
            SectionOutcome,
            {section_id: user.teacher.teaching_assignments.pluck(:section_id) }
        can [:edit_subject_outcomes, :update_subject_outcomes, :view_subject_outcomes],
            SectionOutcome,
            {section: { subject: { subject_manager_id: user.id }}}

        # SectionOutcomeRating
        can [:create, :update],
            SectionOutcomeRating,
            { section_outcome_id: user.teacher.section_outcomes.pluck(:id) }

        # Student
        can [:create, :read, :update, :dashboard, :security, :index, :set_student_temporary_password],
            Student, {school_id: user.school_id }
        can :new, Student

        # Parent
        can [:create, :read, :update, :dashboard, :security, :index, :new, :set_parent_temporary_password],
          Parent,
          { school_id: user.school_id }
        # to do - school admin does not have the following abilities for parents, so does teacher need these?: :create, :read, :update, :dashboard, :security, :index, :new


        # Subject
        can [:read],
            Subject,
            { school_id: user.school_id }
        can [:edit_subject_outcomes, :update_subject_outcomes, :view_subject_outcomes],
            Subject,
            { subject_manager_id: user.id }
          # The ability to Edit_subject_outcomes, etc is also determined by User table. See below.


        # Teacher
        can [:read],Teacher, { id: user.id }  #maybe not needed
        #can [:edit, :sections_list], Teacher, { user.has_permission?('manage_subject_admin')}

        # User
        can [:read, :change_password, :edit, :update, :profile, :sections_list, :account_activity_report, :staff_listing, :dashboard],
          User,
            { id: user.id }

        # User
        # Not doing anything
        # can [:account_activity_report, :staff_listing, :dashboard], User, { school_id: user.school_id }
        # can [:edit_subject_outcomes, :update_subject_outcomes, :view_subject_outcomes], User, { permissions: 'subject_admin' }

        # removed - see simple replacements below - may possibly be relevant if accessible_by is used
        # can [:create, :update, :dashboard, :security, :set_temporary_password], ["system_administrator = 1 or researcher = 1 or school_administrator = 1 or counselor = 1 or teacher = 1"], User do |u|
        #   reject = false
        #   u.role_symbols.each do |r|
        #     reject = true if ![:student, :parent].include?(r)
        #   end
        #   u.school_id == user.school_id and !reject
        # end

        can [:create, :update, :dashboard, :security, :set_temporary_password, :sections_list], User, { student: true}
        can [:create, :update, :dashboard, :security, :set_temporary_password], User, { parent: true}

        # Attendance
        can [:student_attendance_detail_report, :attendance_report], Attendance
        can [:manage],
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
        can [:section_summary_outcome, :section_summary_student, :nyp_outcome, :nyp_student, :progress_rpt_gen, :class_dashboard], Section
        can [:switch, :dashboard, :summary], School
        can [:exp_col_all_evid, :section_outcomes],
            Section
        # can :proficiency_bars, Student
        can [:proficiency_bars, :progress_meters, :view_subject_outcomes], Subject
        can [:staff_listing, :sections_list], User
        can [:tracker_usage], Teacher

        cannot [:edit, :update], User
        cannot [:edit, :update], Student
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
        can [:new], Enrollment

        # Evidence
        can [:create, :rate, :show, :update, :show_attachments],
          Evidence,
          { section: { subject: { school_id: user.school_id } } }
        can [:new], Evidence

        # EvidenceSectionOutcomeRating
        can [:create, :show, :update],
          EvidenceSectionOutcomeRating,
          { evidence_section_outcome: { section_outcome: { section: { subject: { school_id: user.school_id } } } } }
        can [:new], EvidenceSectionOutcomeRating

        # School
        can [:read, :new_year_rollover, :dashboard, :summary],
          School,
          { id: user.school_id }

        # Section
        can [:create, :index, :new_enrollment, :new_evidence, :new_section_outcome,
             :section_outcomes, :show, :sort, :update, :restore_evidence, :section_summary_outcome,
             :section_summary_student, :nyp_student, :nyp_outcome, :student_info_handout,
             :student_info_handout_by_grade, :progress_rpt_gen, :class_dashboard, :edit_section_message,
             :exp_col_all_evid, :list_enrollments, :remove_enrollment, :enter_bulk, :update_bulk,
             :section_outcomes, :new, :create, :section_attendance],
          Section,
          { subject: {school_id: user.school_id }}
        can [:new], Section

        # SectionOutcome
        can [:create, :show, :sort, :update, :evidences_left, :evidences_right, :toggle_marking_period],
            SectionOutcome,
            { section: { subject: { school_id: user.school_id } } }
        can [:new], SectionOutcome

        # SubjectOutcome
        can [:create, :show, :update],
            SubjectOutcome,
            { subject: { school_id: user.school_id } }
        can [:new], SubjectOutcome

        # SectionOutcomeRating
        can [:create, :update],
          SectionOutcomeRating,
          { section_outcome: { section: { subject: { school_id: user.school_id } } } }
        can [:new], SectionOutcomeRating

        # Student
        can [:create, :deactivate, :read, :update, :dashboard, :security, :proficiency_bars, :bulk_upload, :bulk_update, :set_student_temporary_password],
          Student,
          { school_id: user.school_id }
        can [:new], Student

        # Parent
        can [:set_parent_temporary_password],
          Parent,
          { school_id: user.school_id }
        # note teacher has following abilities for parents, so does school admin need these?: :create, :read, :update, :dashboard, :security, :index, :new,

        # Subject
        can [:read, :view_subject_outcomes, :proficiency_bars, :progress_meters],
            Subject,
            { school_id: user.school_id }
        can [:new], Subject

        # Teacher
        can [:read, :create, :update, :dashboard, :tracker_usage],
          Teacher,
          { school_id: user.school_id }
        can [:new], Teacher

        can [:enter_bulk, :update_bulk, :create],
          TeachingAssignment,
          {teacher: {school_id: user.school_id}}
        can [:new], TeachingAssignment

        # User
        can [:create, :read, :update, :set_temporary_password, :staff_account_activity_report, :account_activity_report, :staff_listing, :dashboard, :security, :new_staff, :create_staff, :profile, :sections_list, :bulk_upload_staff, :bulk_update_staff],
          User,
          { school_id: user.school_id }
        can [:read, :change_password, :edit, :update, :profile],
          User,
          { id: user.id }
        can [:new], User

        # Report Card Request
        can [:create, :forward],
          ReportCardRequest
        can [:new], ReportCardRequest

        # Attendance
        can [:student_attendance_detail_report, :attendance_report], Attendance
        can [:manage],
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
        if user.school_id.present? && user.school_id > 0
          can [:section_outcomes],
            Section, { subject: { school_id: user.school_id } }
          can [:read, :create, :update, :subject_admin, :edit_subject_outcomes, :update_subject_outcomes, :view_subject_outcomes],
            Subject, { school_id: user.school_id }
        end

      end

      if user.has_permission?('manage_subject_admin')
        if user.school_id.present? && user.school_id > 0
          can [:edit, :sections_list],
            User,
              { teacher: {school_id: user.school_id} }
        end

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
