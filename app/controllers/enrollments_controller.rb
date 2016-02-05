# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class EnrollmentsController < ApplicationController
  before_filter :authenticate_user!

  load_and_authorize_resource

  def show
    @section = Section.includes(:section_outcomes).find(@enrollment.section_id)
    @student                  = @enrollment.student
    @evidence_ratings         = @student.section_evidence_ratings @enrollment.section_id
    @sy = SchoolYear.find(@section.school_year_id)

    # todo - move this to enrollment controller
    @section_outcome_ratings  = @student.section_section_outcome_ratings @section.id

    @marking_periods = Range::new(1,@section.school.marking_periods)

    @ratings = @enrollment.hash_of_section_outcome_rating_counts
    @ratings.each do |r|
      Rails.logger.debug("*** r: #{r.inspect.to_s}")
    end
    @e_over_cur = @enrollment.count_section_evidence_ratings @enrollment.section_id
    @e_weekly_cur = @enrollment.count_section_evidence_ratings @enrollment.section_id, 1.week.ago

    respond_to do |format|
      format.html
      # format.json # used for Student Bar Charts (charts for all sections for a student)
    end
  end

  # No practical use for an index action at this time.

  def new
    respond_to do |format|
      format.html
    end

  end

  def create
    @enrollment = Enrollment.find_or_initialize_by_student_id_and_section_id(params[:enrollment][:student_id], params[:enrollment][:section_id])
    @enrollment.active = true
    @student = Student.find(params[:enrollment][:student_id])
    @enrollment.student_grade_level = @student.grade_level

    respond_to do |format|
      if @enrollment.save
        # removed automatic copy of prior subject ratings to fix problems and to make it user controllable
        # @student.import_subject_outcome_ratings! @enrollment.section.subject.id, @enrollment.section.id
        format.html { redirect_to(@enrollment.section, :notice => 'Enrollment was successfully created.') }
      else
        @existing_enrollment = Enrollment.find(
          :first,
          :conditions => {
            :student_id => params[:enrollment][:student_id],
            :section_id => params[:enrollment][:section_id],
            :active => false
          }
        )
        if @existing_enrollment.nil?
          format.html { render :action => "new" }
        else
          @existing_enrollment.active = true
          @existing_enrollment.save
          format.html { redirect_to(@enrollment.section, :notice => 'Enrollment was successfully created.') }
        end
      end
    end
  end

  # Enrollments are updated via AJAX (Handlebars templates), so there is no need for an edit action.

  def update
    respond_to do |format|
      if @enrollment.update_attributes params[:enrollment]
        format.js { render js: "window.location.reload();" }
      else
        format.js { render js: "alert('Enrollment not successfully updated.');"}
      end
    end
  end


  # New UI
  # student enrollment bulk entry page
  def enter_bulk
    Rails.logger.debug("*** enter_bulk")
    # authorize! :read, User # force login if not logged in

    num_items = prep_for_bulk_view(params)

    Rails.logger.debug("*** num_items: #{num_items}")
    respond_to do |format|
      get_school_students()
      if @school.id.present?
        if num_items == 0
            flash[:alert] = 'No sections to assign students to.'
           format.html { redirect_to subjects_path }
        else
          format.html
        end
      else
        # @students
        flash[:alert] = "Please pick a school."
        format.html {redirect_to schools_path}
      end
    end
  end


  # New UI
  # student enrollment bulk entry update page
  def update_bulk
    Rails.logger.debug("*** update_bulk")
    # authorize! :read, User # force login if not logged in

    respond_to do |format|

      get_school_students()
      if @school.id.present?
        if false # number of sections for subject is zero
            flash[:alert] = 'No sections to assign students to.'
            format.html { redirect_to subjects_path }
        else
          begin
            ta_params = params['enrollments_attributes']
            Rails.logger.debug("*** ta_params: #{ta_params.inspect}")
            action_count = 0
            if ta_params
              cur_subj_id = ta_params['cur_subject_id'].to_i
              cur_sect_id = ta_params['cur_section_id'].to_i
              subj_id = ta_params['subject_id'].to_i
              sect_id = ta_params['section_id'].to_i
              num_changes = params['num_changes'].to_i
              Rails.logger.debug("*** cur_subj_id: #{subj_id}")
              Rails.logger.debug("*** cur_sect_id: #{cur_sect_id.inspect}")
              Rails.logger.debug("*** subj_id: #{subj_id}")
              Rails.logger.debug("*** sect_id: #{sect_id.inspect}")
              Rails.logger.debug("*** num_changes: #{num_changes.inspect}")
              if cur_sect_id == 0 || cur_sect_id != sect_id
                # no updates, just display updated form for new section
                Rails.logger.debug("*** no changes")
                prep_for_bulk_view(params)
                format.html
              elsif !sect_id.present? || sect_id == 0
                # raise("No section to assign to.")
              else
                Rails.logger.debug("*** start transaction")
                ActiveRecord::Base.transaction do
                  sect = Section.find(sect_id)
                  raise("cannot find section!") if sect.errors.count > 0
                  raise("Section not in subject!") if sect.subject_id != subj_id
                  raise("Section not in this school!") if sect.school_year_id != @school.school_year_id
                  ids = ta_params['id']
                  Rails.logger.debug("*** unassign counts: #{(ids.present? ? ids.count : '0')}")
                  if ids
                    ids.each do |e_id, action|
                      Rails.logger.debug("*** find and deactivate enrollment with id: #{e_id}")
                      raise('invalid enrollment action (not deact) for #') if action != 'deact'
                      enrollment = Enrollment.find(e_id.to_i) # note error here raises exception.
                      enrollment.active = false
                      enrollment.save!
                      action_count += 1
                    end
                  end
                  student_ids = ta_params['student_id']
                  Rails.logger.debug("*** to assign counts: #{(student_ids.present? ? student_ids.count : '0')}")
                  if student_ids
                    student_ids.each do |s_id, s_values|
                      if s_values['action'] == 'create'
                        Rails.logger.debug("*** create new enrollment for student id: #{s_id}, #{s_values}")
                        raise('invalid enrollment action (not create) for #') if s_values['action'] != 'create'
                        grade_level = s_values['grade'].to_i
                        Rails.logger.debug("*** grade level: #{grade_level}")
                        matches = Enrollment.where(section_id: sect_id, student_id: s_id)
                        if matches.count > 0
                          matches.first.active = true
                          matches.first.save!
                        else
                          enrollment = Enrollment.new
                          enrollment.student_id = s_id
                          enrollment.section_id = sect_id
                          enrollment.student_grade_level = grade_level
                          enrollment.save!
                        end
                        action_count += 1
                      elsif  s_values['action'] == 'keep'
                        Rails.logger.debug("*** keep #{s_id}")
                      end
                    end
                  end
                  # raise "Successful Test cancelled" if action_count > 0
                end # transaction
              end
            end
            flash.now[:notify] = "Successfully did #{action_count} assignment changes."
            prep_for_bulk_view(params)
            format.html
          rescue Exception => e
            msg_str = "ERROR: Exception - #{e.message}"
            @errors[:base] = add_error(@errors[:base], msg_str)
            Rails.logger.error(msg_str)
            flash.now[:alert] = msg_str
            prep_for_bulk_view(params)
            format.html
          end # begin
        end
      else
        # @students
        flash[:alert] = "Please pick a school."
        format.html {redirect_to schools_path}
      end

    end # respond_to
  end

  def section_enrollments
    section_id = params[:section_id]
    # @section_enrollments = Enrollment.find(section_id)
    @section_enrollments = Enrollment.limit(2)
    Rails.logger.debug("*** @section_enrollments: #{@section_enrollments.to_json}")
    render json: @section_enrollments.to_json
    # render json: {"hello": "goodbye"}.to_json
  end


  #####################################################################################
  protected

  def add_error(prior_errors, new_error)
    resp = (prior_errors.present? ? prior_errors+', '+new_error : new_error)
  end

  def get_school_students()
    @errors = Hash.new
    @school = get_current_school
    @errors[:base] = add_error(@errors[:base], 'Need to assign school.') if @school.id.blank?
    if @school.has_flag?(School::USER_BY_FIRST_LAST)
      @students = Student.accessible_by(current_ability).order(:first_name, :last_name).scoped
    else
      @students = Student.accessible_by(current_ability).order(:last_name, :first_name).scoped
    end
    @students = @students.where(school_id: @school.id) if @school.id.present?
  end

  def prep_for_bulk_view(params)
    Rails.logger.debug("*** prep_for_bulk_view started")

    @disciplines = Discipline.includes(subjects: {sections: :teachers }).order('disciplines.name, subjects.name, sections.line_number')

    ta_params = params['enrollments_attributes']
    Rails.logger.debug("*** ta_params: #{ta_params.inspect}")

    @subjects = Subject.where(school_id: current_school_id)
    @cur_subject_id = ta_params['subject_id'].to_i if ta_params
    if @cur_subject_id
      @sections = Section.where(subject_id: @cur_subject_id).includes(:subject)
    else
      @sections = []
    end
    @cur_section_id = ta_params['section_id'].to_i if ta_params

    Rails.logger.debug("*** @cur_section_id: #{@cur_section_id}")
    if @cur_section_id.present? && @cur_section_id > 0
      @current_section_assignments = Enrollment.where(section_id: @cur_section_id, active: true)
      @cur_section = Section.find(@cur_section_id)
    else
      @current_section_assignments = []
      @cur_section = nil
    end
    Rails.logger.debug("*** @current_section_assignments: #{@current_section_assignments.inspect}")
    Rails.logger.debug("*** @cur_section: #{@cur_section.inspect}")

    if ta_params
      if @current_section_assignments.count > 0
        @assigned_student_ids = @current_section_assignments.pluck(:student_id)
      else
        @assigned_student_ids = []
      end
      if ta_params['student_id']
        @selected_student_ids = ta_params['student_id'].map {|student_id, action| student_id.to_i}
      else
        @selected_student_ids = []
      end
      @student_ids = @assigned_student_ids + @selected_student_ids
      @selected_students = Student.where(id: @selected_student_ids)
    else
      @student_ids = []
      @selected_students = []
    end
    Rails.logger.debug("*** @student_ids: #{@student_ids}")
    Rails.logger.debug("*** @assigned_student_ids: #{@assigned_student_ids}")
    Rails.logger.debug("*** @selected_student_ids: #{@selected_student_ids}")
    Rails.logger.debug("*** prep_for_bulk_view done")

  end
end
