# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SectionsController < ApplicationController
  # Manually call authorize! after @section is declared because of complicated includes, etc.
  load_and_authorize_resource
  # respond_to :json

  include SectionsHelper

  # New UI Tracker Page
  # Teacher Tracker Page (Section Tracker)
  def show
    Rails.logger.debug("*** show ***")
    # responds to request to display tracker page
    params[:print_unrated] ||= 0
    params[:print_unrated] = params[:print_unrated].to_i

    show_prep_h
    
    params[:marking_periods] ||= @marking_periods.to_a #for when we want the periods that are also changable by user selection in the UI
    params[:marking_periods].map!(&:to_i) #the user may change this to a string value through input boxes

    template = "sections/show"
    template = "sections/reports/#{params[:report]}" if params[:report]

    Rails.logger.debug("*** respond ***")
    respond_to do |format|
        if params[:report].present? && params[:report] == 'progress_reports' && params[:student_id].blank?
        Rails.logger.error("ERROR progress report with no students selected.")
        flash[:alert] = I18n.translate('errors.must_pick_one_item', item: 'Student')
        # attempt to catch no students error. Missing template generates/create or goes to pdf processing
        # template = "generates/create"
        # format.html {render template: 'generates/create'}
        params[:student_id] = []
      end
      format.html { render layout: 'tracker_layout'}
      format.json
      format.pdf do
        response.headers['Accept-Ranges'] = 'none'
        response.headers['Cache-Control'] = 'private, max-age=0, must-revalidate'
        response.headers['Pragma']        = 'public'
        response.headers['Expires']       = '0'
        render template
      end
      format.xlsx do
        response.headers['Accept-Ranges'] = 'none'
        response.headers['Cache-Control'] = 'private, max-age=0, must-revalidate'
        response.headers['Pragma']        = 'public'
        response.headers['Expires']       = '0'
        render layout: false
      end
    end
  end

  def new
    # currently only allow entry into the current school for system administrators
    # @schools = School.accessible_by(current_ability).order('name')
    Rails.logger.debug("*** sections#new, params: #{params}")
    subj_param = params['subject_id']
    Rails.logger.debug("*** sections#new, subj_param: #{subj_param}")
    @school = get_current_school
    @section = Section.new(school_year_id: @school.school_year_id)
    if( subj_param && subj_param =~ /^[0-9]+$/)
      @section.subject_id = subj_param
    end
    @subjects = Subject.where(school_id: @school.id)
    @teachers = Teacher.where(school_id: @school.id).accessible_by(current_ability).alphabetical
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @school = get_current_school
    @section.school_year_id = @school.school_year_id
    @teachers = Teacher.where(school_id: @school.id).accessible_by(current_ability).alphabetical

    respond_to do |format|
      if @section.save
        @teaching_assignments = []
        params[:teaching_assignment_attributes].each do |tapk, tapv|
          if !tapv[:id]
            tapv[:section_id] = @section.id
            @teaching_assignment = TeachingAssignment.create(tapv)
          end
          @teaching_assignments << @teaching_assignment
        end
        format.js
        format.html { redirect_to section_path(@section.id) }
      else
        format.js
        format.html { render 'new' }
      end
    end
  end

  def edit
    @school = get_current_school
    @teachers = Teacher.where(school_id: @school.id).accessible_by(current_ability).alphabetical
    template = params[:template]
    template ||= "edit"

    respond_to do |format|
      # html responds to edit subsections button (to edit the subsections a student belongs to)
      format.html { render template: "sections/edit_subsections" }
      # js responds to edit section in subjects / sections listing
      format.js
    end
  end

  def update
    # responds to edit subsections 'Update Section' button (save student subsection changes)
    @school = get_current_school
    @teachers = Teacher.where(school_id: @school.id).accessible_by(current_ability).alphabetical
    respond_to do |format|
      if @section.update_attributes(params[:section])
        @teaching_assignments = []
        # remove error 500 on filter change in teacher tracker
        if params[:section][:selected_marking_period].present?
          # update marking period filter
          show_prep_h
          format.js { render nothing: true }
        else
          if params[:teaching_assignment_attributes]
            params[:teaching_assignment_attributes].each do |tapk, tapv|
              if !tapv[:id]
                tapv[:section_id] = @section.id
                @teaching_assignment = TeachingAssignment.create(tapv)
              else
                @teaching_assignment = TeachingAssignment.find(tapv[:id])
                TeachingAssignment.destroy(tapv[:id])
              end
              @teaching_assignments << @teaching_assignment
            end
          end
          format.html { redirect_to session[:return_to], :notice => 'Section was successfully updated.' }
          format.js
        end
      else
        err = "Error on update: #{@section.errors}"
        flash[:alert] = err
        format.html { render :action => "edit" }
        format.js
      end
    end
  end

  # new UI
  # respond to ajax call to populate the section select box for the subject
  def index
    @subject_id = params['subject_id'].to_i
    sections_select_info = []
    Section.where(subject_id: @subject_id).each do |s|
      sections_select_info << {id: s.id, name: "#{s.name} - #{s.line_number}"}
    end
    respond_to do |format|
      format.js {render json: sections_select_info.to_json, status: :ok}
    end
  end


  # Non-standard definitions

  # TODO rewrite section reporting bit!

  # new UI
  # bring up new enrollment popup form for teacher tracker page
  def new_enrollment
    @students = @section.school.students.alphabetical - @section.active_students
    @enrollment = Enrollment.new
    # new student and parent for add new student to class (views/students/_form.html.haml)
    @student = Student.new
    @parent = Parent.new
    respond_to do |format|
      format.js
    end
  end

  # new UI
  # bring up remove enrollment popup for teacher tracker page
  def list_enrollments
    @enrollments = @section.enrollments.alphabetical
    @enrollment = Enrollment.new
    respond_to do |format|
      format.js
    end
  end

  # new UI
  # bring up remove enrollment popup for teacher tracker page
  def remove_enrollment
    @enrollments = @section.enrollments.alphabetical
    @enrollment = Enrollment.find(params['section_enrollment_id'])
    @enrollment.update_attribute(:active, false)
    respond_to do |format|
      format.html { redirect_to section_path(@section.id)}
    end
  end

  # new UI
  # Generate Form for Add New Evidence:
  # - sections/#/new_evidence - Toolkit - Add Evidence.
  def new_evidence
    @evidence = Evidence.new
    @eso = EvidenceSectionOutcome.new
    @eso_id = '0'
    @other_sos = SectionOutcome.where(section_id: @section.id, active: true).includes("subject_outcome")
    @esos = []
    @evidence_types   = EvidenceType.all
    # get the other sections that the teacher has in the same subject
    cur_sy_id = @section.subject.school.school_year_id
    if current_user.teacher? || current_user.school_administrator? || current_user.system_administrator?
      if current_user.teacher?
        other_sections = current_user.teacher.teaching_assignments.pluck(:section_id) - [@section.id]
      else
        other_sections = @section.subject.sections.pluck(:id) - [@section.id]
      end
      Rails.logger.debug("*** other_sections: #{other_sections.inspect.to_s}")
      @sections = Section.where(subject_id: @section.subject_id, id: other_sections, school_year_id: cur_sy_id )
      Rails.logger.debug("*** @sections: #{@sections.inspect.to_s}")
    else
      @sections = []
    end
    Rails.logger.debug("*** matching sections for teacher: #{@sections.inspect.to_s}")
    flash[:alert] = ''
    respond_to do |format|
      format.html
    end
  end

  # new UI
  # process updates from:
  # - sections/#/restore_evidence - Toolkit - Restore Evidence.
  def restore_evidence
    Rails.logger.debug("*** SectionsController.restore_evidence")
    @evidences = Evidence.where(section_id: @section.id, active: false)
    Rails.logger.debug("*** respond")
    respond_to do |format|
      format.html
    end
  end

  # new UI
  # generate add Learning Outcome (Section Outcome) page:
  # - sections/#/new_section_outcome - Toolkit - Add Learning Outcome.
  def new_section_outcome
    @avail_subject_outcomes = @section.subject.subject_outcomes - @section.subject_outcomes
    # @inactive_section_outcomes = @section.inactive_section_outcomes
    @subjo_so = Hash.new
    # preload all subject outcomes entries with a blank section outcome
    @avail_subject_outcomes.each do |subjo|
      son = SectionOutcome.new
      son.section_id = @section.id
      son.subject_outcome_id = subjo.id
      son.marking_period = 0
      @subjo_so[subjo.id] = son
    end
    # replace the section outcome entries if they exist already
    @section.inactive_section_outcomes.each do |iso|
      Rails.logger.debug("************ iso = #{iso.inspect.to_s}")
      @subjo_so[iso.subject_outcome_id] = iso
    end
    @marking_periods  = Range::new(1,@section.school.marking_periods)
    Rails.logger.debug("*** current_user_id: #{current_user.id}")
    Rails.logger.debug("*** @section.subject.subject_manager_id: #{@section.subject.subject_manager_id}")
    @is_subject_manager = (
      (
        current_user.id == @section.subject.subject_manager_id  ||
        (current_user.school_administrator? && get_current_school.id == current_user.school_id) ||
        current_user.system_administrator?
      ) ? true : false
    )
    respond_to do |format|
      format.html
    end
  end

  def section_outcomes
    @section_outcomes = Section.find(params[:id]).section_outcomes

    respond_to do |format|
      format.json
    end
  end

  def set_section_message
    if @section.update_attributes params[:section]
      render :update do |page|
        page.replace_html "section_message_content", link_to_function(allow_markup(@section.message), "createSectionMessageForm("+@section.id.to_s+")")
      end
    end
  end

  def sort
    @teacher                          = Teacher.find(params[:teacher_id])
    @sections                         = @teacher.sections
    @sections.each do |section|
      section.position = section.id + 100 if section.position == nil
      section.position                = params["sections"].index(section.id.to_s).to_i+1
      section.save
    end
    render :nothing                   => true
  end

  def show_experimental
    unless request.format == "text/html"
      @section = Section.includes(
        section_outcomes: [
          :section,
          :subject_outcome, {
            evidence_section_outcomes: [
              {evidence: :evidence_type},
              :section
            ]
          }
        ]
      ).find(params[:id])
      @students                 = @section.active_students(subsection: params[:subsection])
      @student_ids              = @students.collect { |a| a.id }
      @nested_ratings           = @section.data_array(@student_ids)
      respond_to do |format|
        format.html
        format.json
      end
    end
  end

  # new UI
  # Generate the Section Summary by Learning Outcome report
  # from Toolkit - Generate Reports selection, POST "/generates" forward to here.
  # /sections/#/section_summary_outcome
  def section_summary_outcome
    errors = ""
    begin
      @section = Section.includes(:section_outcomes).find(params[:id])
    rescue => e
      errors += " - Cannot find section #{params[:id]}, #{e.message}"
      Rails.logger.error("ERROR: cannot find section")
      flash[:alert] = 'ERRORS'+errors
    end
    respond_to do |format|
      format.html
    end
  end

  # new UI
  # Generate the Section Summary by Student report
  # from Toolkit - Generate Reports selection - POST "/generates" forward to here.
  # /sections/#/section_summary_student
  def section_summary_student
    errors = ""
    begin
      @section = Section.includes(enrollments: :student).find(params[:id])
    rescue => e
      errors += " - Cannot find section #{params[:id]}, #{e.message}"
      Rails.logger.error("ERROR: cannot find section")
      flash[:alert] = 'ERRORS'+errors
    end
    respond_to do |format|
      format.html
    end
  end

  # new UI
  # Generate the Not yet Proficient by Student report
  # from Toolkit - Generate Reports selection - POST "/generates" forward to here.
  # /sections/#/nyp_student
  def nyp_student
    errors = ""
    begin
      @section = Section.includes(enrollments: :student).find(params[:id])
    rescue => e
      errors += " - Cannot find section #{params[:id]}, #{e.message}"
      Rails.logger.error("ERROR: cannot find section")
      flash[:alert] = 'ERRORS'+errors
    end
    respond_to do |format|
      format.html
    end
  end

  # new UI
  # Generate the Not yet Proficient by Learning Outcome report
  # from Toolkit - Generate Reports selection - POST "/generates" forward to here.
  # /sections/#/nyp_outcome
  def nyp_outcome
    errors = ""
    begin
      @section = Section.includes(:section_outcomes).find(params[:id])
    rescue => e
      errors += " - Cannot find section #{params[:id]}, #{e.message}"
      Rails.logger.error("ERROR: cannot find section")
      flash[:alert] = 'ERRORS'+errors
    end
    respond_to do |format|
      format.html
    end
  end

  # new UI
  # Generate the Student Handout (for a single section)
  # from Toolkit - Generate Reports selection - POST "/generates" forward to here.
  # /sections/#/student_info_handout
  def student_info_handout
    errors = ""
    begin
      @section = Section.includes(:section_outcomes).find(params[:id])
      @students = @section.active_students(subsection: params[:subsection])
    rescue => e
      errors += " - Cannot find section #{params[:id]}, #{e.message}"
      Rails.logger.error("ERROR: cannot find section")
      flash[:alert] = 'ERRORS'+errors
    end
    template = "sections/reports/student_accounts"
    respond_to do |format|
      format.pdf do
        response.headers['Accept-Ranges'] = 'none'
        response.headers['Cache-Control'] = 'private, max-age=0, must-revalidate'
        response.headers['Pragma']        = 'public'
        response.headers['Expires']       = '0'
        render template
      end
    end
  end

  # new UI
  # Generate the Student Handout (for school by grade_level)
  # from Toolkit - Generate Reports selection - POST "/generates" forward to here.
  # /sections/#/student_info_handout_by_grade
  def student_info_handout_by_grade
    errors = ""
    begin
      @students = Student.includes(:parent).where(school_id: @current_school.id, active: true).order(:grade_level, :last_name, :first_name)
    rescue => e
      errors += " - Cannot find section #{params[:id]}, #{e.message}"
      Rails.logger.error("ERROR: cannot find section")
      flash[:alert] = 'ERRORS'+errors
    end
    @students.each do |s|
      Rails.logger.debug("$$$ #{s.grade_level}, #{s.last_name}, #{s.first_name}")
    end
    template = "sections/reports/student_accounts_by_grade"
    respond_to do |format|
      format.pdf do
        response.headers['Accept-Ranges'] = 'none'
        response.headers['Cache-Control'] = 'private, max-age=0, must-revalidate'
        response.headers['Pragma']        = 'public'
        response.headers['Expires']       = '0'
        render template
      end
    end
  end

  # new UI
  # Generate the Not yet Proficient by Learning Outcome report
  # from Toolkit - Generate Reports selection - POST "/generates" forward to here.
  # /sections/#/progress_rpt_gen
  def progress_rpt_gen
    errors = ""
    begin
      @section = Section.includes(:section_outcomes).find(params[:id])
      @students = @section.active_students(subsection: params[:subsection])
      @marking_periods = Range::new(1,@section.school.marking_periods) #for when we want to set value in the school
    rescue => e
      errors += " - Cannot find section #{params[:id]}, #{e.message}"
      Rails.logger.error("ERROR: cannot find section")
      flash[:alert] = 'ERRORS'+errors
    end
    respond_to do |format|
      format.html
    end
  end

  # New UI
  # Class Dashboard page
  def class_dashboard
    #
    @section = Section.find(params[:id])
    Rails.logger.debug("*** @section: #{@section.inspect.to_s}")

    # used for both overall student performance and section proficiency bars
    @ratings = SectionOutcomeRating.hash_of_section_outcome_rating_by_section(section_ids: [@section.id])

    # used for both section_outcome proficiency bars
    @so_ratings = SectionOutcomeRating.hash_of_section_outcome_rating_by_so(section_ids: [@section.id])

    unique_student_ids = Enrollment.where(section_id: @section.id).pluck(:student_id).uniq
    Rails.logger.debug("*** unique_student_ids = #{unique_student_ids.inspect.to_s}")

    @students = Student.alphabetical.where(id: unique_student_ids)

    @student_ratings = SectionOutcomeRating.hash_of_students_rating_by_section(section_ids: [@section.id])

    # recent activity
    @recent10 = Student.where('current_sign_in_at IS NOT NULL AND id in (?)', unique_student_ids).order('current_sign_in_at DESC').limit(10)

    # current Weeks Evidence
    today = Date.today
    @cur_evidences = Evidence.active_evidences.where(section_id: @section.id, assignment_date: today.beginning_of_week(:sunday)..today.end_of_week(:sunday)).order(:assignment_date)

    respond_to do |format|
      format.html
    end
  end

  # New UI
  # Class Tracker page collapse all evidences
  def exp_col_all_evid
    Rails.logger.debug("*** exp_col_all_evid params: #{params.inspect.to_s}")
    @section = Section.includes(:section_outcomes).find(params[:id])
    @error_count = 0
    if params[:minimized].nil?
      flash[:alert] = "ERROR: Missing minimized argument!"
      error_count += 1
    elsif params[:minimized] == 'true'
      minimized = true
    elsif params[:minimized] == 'false'
      minimized = false
    end
    if @error_count == 0
      Rails.logger.debug("*** @section: #{@section.inspect.to_s}")
      @section.section_outcomes.each do |so|
        so.update_attribute(:minimized, minimized)
        if so.errors.count > 0
          @error_count += 1
          flash[:alert] = "Error updating minimized"
        end
      end
    end
    respond_to do |format|
      format.js
    end
  end

  # New UI
  # edit section message popup
  def edit_section_message
    Rails.logger.debug("*** edit_section_message")
    @section = Section.find(params[:id])
    Rails.logger.debug("*** @section: #{@section.inspect.to_s}")
  end


  # New UI
  # update section message from edit_section_message popup
  def update_section_message
    Rails.logger.debug("*** update_section_message #{params[:section].keys}")
    respond_to do |format|
      if params[:section].keys == %w(message)
        if @section.update_attributes(params[:section])
          Rails.logger.debug("*** params: #{params.inspect.to_s}")
          format.js
        else
          err = "*** error on update_section_message #{@section.errors.inspect}"
          Rails.logger.debug(err)
          flash[:alert] = err
          format.js
        end
      else
        err = "ERROR - update_section_message includes extra params"
        Rails.logger.error(err)
        @section.errors.add(base: err)
        flash[:alert] = err
        format.js
      end
    end
  end

  # New UI
  # section bulk entry page
  def enter_bulk
    Rails.logger.debug("*** enter_bulk")
    all_subject_ids = Subject.where(school_id: current_school_id).pluck(:id)
    subjects_ids_with_sections = Section.where(subject_id: all_subject_ids).pluck(:subject_id).uniq
    empty_subjects = all_subject_ids - subjects_ids_with_sections
    @subjects = Subject.where(id: empty_subjects).order(:name)
    @school = get_current_school
    err_str = ''
    err_str = 'Need to assign school.' if @school.id.blank?
    err_str = 'Need to assign school year.' if @school.school_year.blank?
    err_str = 'Cannot run Section Bulk Entry, all subjects have sections assigned' if @subjects.count == 0
    respond_to do |format|
      if err_str.present?
        format.html { redirect_to subjects_path, alert: err_str }
      else
        format.html
      end
    end
  end


  # New UI
  # section bulk entry update page
  def update_bulk
    Rails.logger.debug("*** update_bulk")
    all_subject_ids = Subject.where(school_id: current_school_id).pluck(:id)
    subjects_ids_with_sections = Section.where(subject_id: all_subject_ids).pluck(:subject_id).uniq
    empty_subjects = all_subject_ids - subjects_ids_with_sections
    @subjects = Subject.where(id: empty_subjects).order(:name)
    sec_ps = params['section']
    respond_to do |format|
      begin
        @school = get_current_school
        raise('Need to assign school.') if @school.id.blank?
        raise('Need to assign school year.') if @school.school_year.blank?
        school_year_id = @school.school_year_id
        sections = Section.where school_year_id: @school.school_year_id
        raise('Cannot run Section Bulk Entry, all subjects have sections assigned') if @subjects.count == 0
        ActiveRecord::Base.transaction do
          if sec_ps
            sec_ps.each do |row, sec_p_cols|
              sec_p_cols.each do |col, sec_p_hash|
                if sec_p_hash['value'].present?
                  sec = Section.new
                  sec.line_number = sec_p_hash['value']
                  sec.subject_id = sec_p_hash['subject_id']
                  sec.school_year_id = school_year_id
                  if !sec.save
                    raise("Errors updating section: #{sec.errors.full_messages}")
                  else
                    # automatically create Section Outcomes from Subject Outcomes for this subject
                    subjos = SubjectOutcome.where(subject_id: sec.subject_id, active: true)
                    subjos.each do |subjo|
                      secto = SectionOutcome.new
                      secto.section_id = sec.id
                      secto.subject_outcome_id = subjo.id
                      secto.marking_period = subjo.marking_period
                      raise("Errors updating section outcome: #{secto.errors.full_messages}") if !secto.save
                    end
                  end
                end
              end
            end
          end
          @sections = Section.where(school_year_id: @school.school_year_id, subject_id: empty_subjects)
        end #transaction
        format.html
      rescue Exception => e
        msg_str = "ERROR: Exception - #{e.message}"
        @school.errors.add(:base, msg_str)
        Rails.logger.error(msg_str)
        @sections = Section.where(school_year_id: @school.school_year_id, subject_id: empty_subjects)
        format.html
      end
    end
  end


end
