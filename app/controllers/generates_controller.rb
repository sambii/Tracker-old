# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
# generates_controller.rb
class GeneratesController < ApplicationController
  # Not hooked up to a database table / ActiveRecord model like the other controllers. Used to serve
  # semi-static pages that still need some server information.

  # new UI
  # Generate Form selecting options for generated listings
  # - listings - Toolkit - Generate Listings
  # GET "/generates/new"
  def new
    authorize! :read, Generate
    @generate = Generate.new
    @section_id = params[:section_id] if params[:section_id]
    begin
      @section = Section.find(@section_id)
      Rails.logger.debug("*** current section = #{@section.name} - #{@section.line_number}")
    rescue => e
      Rails.logger.debug("*** NO current section")
      @section_id = params[:section_id]
    end
    @school = get_current_school
    if !@school.id.nil?
      @subjects = Subject.accessible_by(current_ability, :show).where(school_id: @school.id).order('subjects.name')
      @subject_sections = Section.accessible_by(current_ability, :show).includes(:subject).where(school_year_id: @school.school_year_id).order('subjects.name, sections.line_number')
      @marking_periods = Range::new(1,@school.marking_periods)
      @school_students = Student.accessible_by(current_ability, :show).alphabetical.where(school_id: @school.id)
      @school_year = SchoolYear.where(id: @school.school_year_id).first
      @range_start = @school_year.starts_at
      @range_end = @school_year.ends_at
    end
    respond_to do |format|
      if !current_user
        Rails.logger.debug("*** no current user, go to root page")
        format.html { redirect_to root_path}
      elsif @school.id.nil?
        Rails.logger.debug("*** no current school, go to school select page")
        flash[:alert] = I18n.translate('errors.invalid_school_pick_one')
        format.html { redirect_to schools_path}
      else
        Rails.logger.debug("*** OK, default response")
        format.html
      end
    end
  end


  # new UI
  # forward a report to run to proper controller action if valid parameters entered
  # otherwise send errors back to form for resubmission.
  # POST "/generates"
  def create
    authorize! :read, Generate
    Rails.logger.debug("*** params: #{params.inspect}")
    params_gen = params[:generate]
    @generate = Generate.new(params_gen)
    Rails.logger.debug ("@generate = #{@generate.inspect.to_s}")
    if @generate.valid?   #see validators/generate_validator.rb
      Rails.logger.debug("record is valid")
    else
      Rails.logger.debug("@generate.errors = #{@generate.errors.inspect.to_s}")
      Rails.logger.debug("record is NOT valid")
    end
    @section_id = params[:section_id] if params[:section_id]
    @section_id = @generate.section_id if @generate.section_id
    begin
      @section = Section.find(@section_id)
      Rails.logger.debug("*** current section = #{@section.name} - #{@section.line_number}")
    rescue => e
      Rails.logger.debug("*** NO current section")
      @section_id = params[:section_id]
    end
    @school = get_current_school
    if !@school.id.nil?
      @subjects = Subject.where(school_id: @school.id).order('subjects.name')
      @subject_sections = Section.includes(:subject).where(school_year_id: @school.school_year_id).order('subjects.name, sections.line_number')
      @marking_periods = Range::new(1,@school.marking_periods)
      @school_students = Student.alphabetical.where(school_id: @school.id)
      @range_start = params_gen[:start_date].truncate(10, omission: '')
      @range_end = params_gen[:end_date].truncate(10, omission: '')
    end
    respond_to do |format|
      if !current_user
        format.html { redirect_to root_path}
      elsif @school.id.nil?
        flash[:alert] = I18n.translate('errors.invalid_school_pick_one')
        format.html { redirect_to schools_path}
      elsif @generate.errors.count > 0
        format.html
      else
        format.html {redirect_to tracker_usage_teachers_path} if @generate.name == 'tracker_usage'
        format.html {redirect_to section_summary_outcome_section_path(@section.id)} if @generate.name == 'ss_by_lo'
        format.html {redirect_to section_summary_student_section_path(@section.id)} if @generate.name == 'ss_by_stud'
        format.html {redirect_to nyp_student_section_path(@section.id)} if @generate.name == 'nyp_by_stud'
        format.html {redirect_to nyp_outcome_section_path(@section.id)} if @generate.name == 'nyp_by_lo'
        format.html {redirect_to student_info_handout_section_path(@section.id)} if @generate.name == 'student_info'
        format.html {redirect_to student_info_handout_by_grade_sections_path()} if @generate.name == 'student_info_by_grade'
        format.html {redirect_to progress_rpt_gen_section_path(@section.id)} if @generate.name == 'progress_rpt_gen'
        format.html {redirect_to students_report_path('proficiency_bar_chart')} if @generate.name == 'proficiency_bars_by_student'
        format.html {redirect_to proficiency_bars_subjects_path} if @generate.name == 'proficiency_bars_by_subject'
        format.html {redirect_to progress_meters_subjects_path} if @generate.name == 'progress_meters_by_subject'
        # code to generate single student bar chart
        # format.html {redirect_to xxxxxx_path(@generate.student_id)} if @generate.name == 'proficiency_bars' && @generate.student_id != ''
        format.html {redirect_to create_report_card_path(grade_level: @generate.grade_level)} if @generate.name == 'report_cards'
        format.html {redirect_to account_activity_report_users_path()} if @generate.name == 'account_activity'
        format.html {redirect_to section_attendance_xls_attendances_path()} if @generate.name == 'section_attendance_xls'
        format.html {redirect_to controller: :attendances, action: :attendance_report, subject_id: params_gen[:subject_id], start_date: @range_start, end_date: @range_end} if @generate.name == 'attendance_report'
        format.html {redirect_to view_context.user_dashboard_path(current_user),
          alert: 'Invalid Report Chosen!'
        }
      end
    end
  end
end
