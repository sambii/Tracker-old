# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class AttendancesController < ApplicationController

  include AttendancesHelper

  respond_to :html

  before_filter :valid_current_school

  def index
    @attendance = Attendance.new
    @attendance.school_id = current_school_id
    authorize! :manage, @attendance # only let maintainers do these things
    @attendance_date_field = params[:attendance_date_field] ? params[:attendance_date_field] : I18n.localize(Time.now.to_date)
    @school = get_current_school
    Rails.logger.debug("***** @school: #{@school.inspect.to_s}")
    @attendance_types = AttendanceType.where(school_id: @school.id)
    Rails.logger.debug("***** @school: #{@school.inspect.to_s}")
    @excuses = Excuse.where(school_id: @school.id)
    @attendances = Attendance.includes([:excuse, :attendance_type]).where(school_id: current_school_id, attendance_date: @attendance_date_field)
    respond_with @attendances
  end

  def show
    find_attendance
    authorize! :update, @attendance
    respond_with @attendance
  end

  def new
    @attendance = Attendance.new
    @attendance.school_id = @school.id
    authorize! :update, @attendance
    respond_with @attendance
  end

  def create
    @attendance = Attendance.new(params[:attendance])
    @attendance.school_id = current_school_id
    authorize! :update, @attendance
    if @attendance.save
      flash[:notice] = I18n.translate('alerts.successfully') +  I18n.translate('action_titles.created')
      redirect_to action: 'index'
    else
      flash[:alert] = I18n.translate('alerts.had_errors') + I18n.translate('action_titles.create')
      respond_with @attendance_type
    end
  end

  def edit
    find_attendance
    authorize! :update, @attendance
    @attendance_date_field = params[:attendance_date_field] ? params[:attendance_date_field] : I18n.localize(Time.now.to_date)
    @school = get_current_school
    @attendance_types = AttendanceType.where(school_id: @school.id)
    @excuses = Excuse.where(school_id: @school.id)
    respond_with @attendance
  end

  def update
    find_attendance
    authorize! :update, @attendance
    if @attendance.update_attributes(params[:attendance])
      flash[:notice] = I18n.translate('alerts.successfully') +  I18n.translate('action_titles.updated')
      redirect_to action: 'index'
    else
      flash[:alert] = I18n.translate('alerts.had_errors') + I18n.translate('action_titles.update')
      respond_with @attendance
    end
  end

  def destroy
    find_attendance
    authorize! :update, @attendance
    @attendance.active = false
    if @attendance.save
      flash[:notice] = I18n.translate('alerts.successfully') +  I18n.translate('action_titles.deleted')
      redirect_to action: 'index'
    else
      flash[:alert] = I18n.translate('alerts.had_errors') + I18n.translate('action_titles.delete')
      respond_with @attendance
    end
  end


  # GET /attendances/section_attendance_by_date?attendance_date_field=2013-09-01&section_id=53
  # to list the section attendance for a specific date
  def section_attendance_by_date
    @section_id = params[:section_id] ? params[:section_id] : params[:id]
    @test_auth_item = Attendance.new
    @test_auth_item.school_id = current_school_id
    a_user = User.where(school_id: current_school_id).first
    @test_auth_item.user_id = a_user.id
    @test_auth_item.section_id = @section_id
    authorize! :manage, @test_auth_item # only let maintainers do these things
    @attendance_date_field = params[:attendance_date_field] ? params[:attendance_date_field] : I18n.localize(Time.now.to_date)
    load_non_attendance_section_attendance_fields(@section_id)
    load_section_attendance_fields(@section_id, @attendance_date_field)
    session[:close_to_path] = section_path(@section_id)
    Rails.logger.debug("*** @attendances = #{@attendances.count}")
    respond_with @attendances
  end

  # GET /attendances/section_attendance?(#section_id)
  # to list the section attendance for today
  def section_attendance
    @section_id = params[:section_id] ? params[:section_id] : params[:id]
    @test_auth_item = Attendance.new
    @test_auth_item.school_id = current_school_id
    a_user = User.where(school_id: current_school_id).first
    raise("ERROR: no users in this school") if a_user.blank?
    @test_auth_item.user_id = a_user.id
    @test_auth_item.section_id = @section_id
    authorize! :manage, @test_auth_item # only let maintainers do these things
    @attendance_date_field = params[:attendance_date] ? params[:attendance_date] : I18n.localize(Time.now.to_date)
    load_non_attendance_section_attendance_fields(@section_id)
    load_section_attendance_fields(@section_id, @attendance_date_field)
    session[:close_to_path] = section_path(@section_id)
    Rails.logger.debug("*** @attendances = #{@attendances.count}")
    respond_with @attendances
  end

  # POST /attendances/section_attendance_update
  def section_attendance_update
    @section_id = params[:section_id] ? params[:section_id] : params[:id]
    @test_auth_item = Attendance.new
    @test_auth_item.school_id = current_school_id
    a_user = User.where(school_id: current_school_id).first
    @test_auth_item.user_id = a_user.id
    @test_auth_item.section_id = params[:section_id] if params[:section_id]
    authorize! :manage, @test_auth_item # only let maintainers do these things

    @attendance_date_field = params[:attendance_date] ? params[:attendance_date] : I18n.localize(Time.now.to_date)
    load_non_attendance_section_attendance_fields(@section_id)
    # loop through each student attendance parameter group (attendance_####)
    # build the @attendances array for display back to the user
    @attendances = []
    params.each do |key, value|
      key_split = key.split(/_/)
      if key_split[0] == 'attendance' && key_split[1] == value['user_id']
        record = process_attendance_update(value, current_school_id, @test_auth_item.section_id)
        @attendances << record
      end # end if attendance_#### parameter
    end # end params loop
    session[:close_to_path] = section_path(params[:section_id])
    flash[:notice] = I18n.translate('alerts.success') if flash[:alert].blank? && flash.now[:alert].blank?
    respond_with @attendances
  end

  def section_attendance_xls
    @school = get_current_school
    @school_year = SchoolYear.where(id: @school.school_year_id).first
    @attendances = Attendance.includes(:student, :section => :subject).order("users.last_name, users.first_name, subjects.name, sections.line_number").where(school_id: @school.id, attendance_date: @school_year.starts_at..@school_year.ends_at)
    @attendance_types = AttendanceType.all
    out_filename = "#{@school.acronym}_section_attendance_#{Time.now.strftime("%Y_%b_%d_%H_%M_%S")}.xlsx"
    # render xlsx: 'section_attendance_xls', disposition: 'inline' # doesn't seem to work
    respond_to do |format|
      format.xlsx do
        response.headers['Accept-Ranges'] = 'none'
        response.headers['Cache-Control'] = 'private, max-age=0, must-revalidate'
        response.headers['Pragma']        = 'public'
        response.headers['Expires']       = '0'
        response.headers['Content-Disposition'] = "attachment; filename='#{out_filename}'"
        render
      end
    end
  end

  def attendance_report
    Rails.logger.debug("*** attendance_report params: #{params.inspect}")
    authorize! :read, Generate
    authorize! :attendance_report, Attendance
    @school = get_current_school
    @subject = (params[:subject_id].present?) ? Subject.find(params[:subject_id]) : nil
    @section = (params[:subject_section_id].present? && params[:subject_section_id] != 'subj') ? Section.find(params[:subject_section_id]) : nil
    start_date = Time.new(*(params[:start_date].split('-'))).to_date
    end_date = Time.new(*(params[:end_date].split('-'))).to_date

    if @school.id.present?
      @school_year = SchoolYear.where(id: @school.school_year_id).first
      if @section
        # section report
        rpt_sections = [@section.id]
      elsif @subject
        # subject report
        rpt_sections = Section.where(subject_id: @subject.id, school_year_id: @school_year.id)
      else
        # error
        rpt_sections = []
      end
      @attendances = Attendance.includes(:student, :section => :subject).where(school_id: @school.id, attendance_date: start_date..end_date, section_id: rpt_sections).scoped
      # see if attendance type filter is set
      if params[:attendance_type_id].present?
        # attendance report for only attendance type specified
        @attendances = @attendances.where(attendance_type_id: params[:attendance_type_id]).scoped
        @attendance_types = AttendanceType.where(school_id: @school.id, id: params[:attendance_type_id])
        @deact_attendance_types = []
        @attendance_count_deactivated = 0
      else
        # regular attendance report (for all attendance_types)
        @attendance_types = AttendanceType.where(school_id: @school.id, active: true).order(:description)
        @deact_attendance_types = AttendanceType.where(school_id: @school.id, active: false)
        @attendance_count_deactivated = @attendances.where(attendance_type_id: @deact_attendance_types.pluck(:id)).count
      end
      if @school.has_flag?(School::USER_BY_FIRST_LAST)
        @attendances = @attendances.order("subjects.name, sections.line_number, users.first_name, users.last_name").all
      else
        @attendances = @attendances.order("subjects.name, sections.line_number, users.last_name, users.first_name").all
      end
    else
      # missing school - set empty scope
      @attendances.where('false').all
    end
    @att_types_names = @attendance_types.map {|at| at.description }
    @start_date = start_date.strftime('%v')
    @end_date = end_date.strftime('%v')
    respond_to do |format|
      if @school.id.nil?
        Rails.logger.debug("*** no current school, go to school select page")
        flash[:alert] = I18n.translate('errors.invalid_school_pick_one')
        format.html { redirect_to schools_path}
      elsif @subject.present? && @subject.school_id != @school.id
        Rails.logger.debug("*** subject not in this school")
        flash[:alert] = "Subject not in this school."
        format.html { redirect_to schools_path}
      else
        format.html
      end
    end
  end

  def student_attendance_detail_report
    Rails.logger.debug("*** student_attendance_detail_report params: #{params.inspect}")
    authorize! :read, Generate
    authorize! :student_attendance_detail_report, Attendance
    # using cancan's accessible_by, so if not authorized, nothing will be returned.
    @school = get_current_school
    p_student_id = params[:student_id]
    @student = (p_student_id.present? && p_student_id != 'all') ? Student.find(params[:student_id]) : nil
    start_date = Time.new(*(params[:start_date].split('-'))).to_date
    end_date = Time.new(*(params[:end_date].split('-'))).to_date

    if @school.id.present?
      @school_year = SchoolYear.where(id: @school.school_year_id).first
      if @school.has_flag?(School::USER_BY_FIRST_LAST)
        @attendances = Attendance.includes(:student).order("users.first_name, users.last_name", "attendances.attendance_date").accessible_by(current_ability).scoped
      else
        @attendances = Attendance.includes(:student).order("users.last_name, users.first_name", "attendances.attendance_date").accessible_by(current_ability).scoped
      end
      # see if attendance type filter is set
      if params[:attendance_type_id].present?
        # attendance report for only attendance type specified
        @attendances = @attendances.where(school_id: @school.id, attendance_date: start_date..end_date, attendance_type_id: params[:attendance_type_id]).scoped
        @attendance_types = AttendanceType.where(id: params[:attendance_type_id])
        @deact_attendance_types = []
        @attendance_count_deactivated = 0
      else
        # regular attendance report (for all attendance_types)
        @attendances = @attendances.where(school_id: @school.id, attendance_date: start_date..end_date).scoped
        @attendance_types = AttendanceType.where(school_id: @school.id, active: true).order(:description)
        @deact_attendance_types = AttendanceType.where(school_id: @school.id, active: false)
        @attendance_count_deactivated = @attendances.where(attendance_type_id: @deact_attendance_types.pluck(:id)).count
      end
    else
      # empty scope
      @attendances.where('false').scoped
    end
    if @student.present?
      @attendances = @attendances.where(user_id: @student.id)
    else
      @attendances = @attendances.all
    end

    @att_types_names = @attendance_types.map {|at| at.description }
    @start_date = start_date.strftime('%v')
    @end_date = end_date.strftime('%v')
    @details = params[:details]
    Rails.logger.debug("*** details: #{@details.inspect}")
    respond_to do |format|
      if @school.id.nil?
        Rails.logger.debug("*** no current school, go to school select page")
        flash[:alert] = I18n.translate('errors.invalid_school_pick_one')
        format.html { redirect_to schools_path}
      elsif @student.present? && @student.school_id != @school.id
        Rails.logger.debug("*** student not in this school")
        flash[:alert] = "Student not in this school."
        format.html { redirect_to schools_path}
      else
        format.html
      end
    end
  end

  def attendance_maintenance
    authorize! :read, AttendanceType
    authorize! :read, Excuse
    @school = get_current_school
    @attendance_types = AttendanceType.where(school_id: current_school_id)
    @excuses = Excuse.where(school_id: current_school_id)
    flash[:alert] = ''
  end


private

  def find_attendance
    if valid_current_school
      @attendance = Attendance.includes(:school).where(id: params[:id], school_id: current_school_id).first
    end
  end

end
