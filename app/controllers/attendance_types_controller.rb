# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class AttendanceTypesController < ApplicationController

  respond_to :html

  before_filter :valid_current_school

  def index
    # set to allow any user to see the list of Attendance Types
    authorize! :read, AttendanceType
    @attendance_types = AttendanceType.where(school_id: current_school_id)
    respond_with @attendance_types
  end

  # New UI
  def new
    @attendance_type = AttendanceType.new
    @attendance_type.school_id = current_school_id
    authorize! :update, @attendance_type # only let maintainers do these things
    respond_to do |format|
      format.js
    end
  end

  # New UI
  def create
    @attendance_type = AttendanceType.new(params[:attendance_type])
    @attendance_type.school_id = current_school_id
    authorize! :update, @attendance_type # only let maintainers do these things
    if @attendance_type.save
      flash[:notice] = I18n.translate('alerts.successfully') +  I18n.translate('action_titles.created')
    else
      flash[:alert] = I18n.translate('alerts.had_errors') + I18n.translate('action_titles.create')
    end
    respond_to do |format|
      format.js
    end
  end

  # New UI
  def edit
    find_attendance_type
    authorize! :update, @attendance_type
    respond_to do |format|
      format.js
    end
  end

  # New UI
  def update
    find_attendance_type
    authorize! :update, @attendance_type
    if @attendance_type.update_attributes(params[:attendance_type])
      flash[:notice] = I18n.translate('alerts.successfully') +  I18n.translate('action_titles.updated')
    else
      flash[:alert] = I18n.translate('alerts.had_errors') + I18n.translate('action_titles.update')
    end
    respond_to do |format|
      format.js
    end
  end

  def destroy
    find_attendance_type
    authorize! :update, @attendance_type
    @attendance_type.active = false
    if @attendance_type.save
      flash[:notice] = I18n.translate('alerts.successfully') +  I18n.translate('action_titles.deleted')
      redirect_to action: 'index'
    else
      flash[:alert] = I18n.translate('alerts.had_errors') + I18n.translate('action_titles.delete')
      respond_with @attendance_type
    end
  end

  private

  def find_attendance_type
    if valid_current_school
      @attendance_type = AttendanceType.includes(:school).where(id: params[:id], school_id: current_school_id).first
    end
  end

end
