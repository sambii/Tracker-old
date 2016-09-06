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
    authorize! :read, @test_auth_item
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
    authorize! :read, @test_auth_item
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
    authorize! :manage, @test_auth_item

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
    @school = get_current_school
    @school_year = SchoolYear.where(id: @school.school_year_id).first
    @subject = Subject.find(params[:subject_id]) if params[:subject_id]
    rpt_subject_id = params[:subject_id].to_i
    start_date = Time.new(*(params[:start_date].split('-'))).to_date
    end_date = Time.new(*(params[:end_date].split('-'))).to_date

    @attendances = Attendance.includes(:student, :section => :subject).order("users.last_name, users.first_name, subjects.name").where(school_id: @school.id, attendance_date: start_date..end_date, sections: {subject_id: rpt_subject_id})
    @attendance_types = AttendanceType.where(school_id: @school.id, active: true).order(:description)
    @att_types_names = @attendance_types.map {|at| at.description }
    @start_date = start_date.strftime('%v')
    @end_date = end_date.strftime('%v')
    respond_with @attendances
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
