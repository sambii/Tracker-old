# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class ExcusesController < ApplicationController

  respond_to :html

  before_filter :valid_current_school

  def index
    # set to allow any user to see the list of excuses
    authorize! :read, Excuse
    @excuses = Excuse.where(school_id: current_school_id)
    respond_with @excuses
  end

  # New UI
  def new
    @excuse = Excuse.new
    @excuse.school_id = current_school_id
    authorize! :update, @excuse # only let maintainers do these things
    respond_to do |format|
      format.js
    end
  end

  # New UI
  def create
    @excuse = Excuse.new(params[:excuse])
    @excuse.school_id = current_school_id
    authorize! :update, @excuse # only let maintainers do these things
    if @excuse.save
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
    find_excuse
    authorize! :update, @excuse # only let maintainers do these things
    respond_to do |format|
      format.js
    end
  end

  # New UI
  def update
    find_excuse
    authorize! :update, @excuse # only let maintainers do these things
    if @excuse.update_attributes(params[:excuse])
      flash[:notice] = I18n.translate('alerts.successfully') +  I18n.translate('action_titles.updated')
    else
      flash[:alert] = I18n.translate('alerts.had_errors') + I18n.translate('action_titles.update')
    end
    respond_to do |format|
      format.js
    end
  end

  def destroy
    find_excuse
    authorize! :update, @excuse # only let maintainers do these things
    @excuse.active = false
    if @excuse.save
      flash[:notice] = I18n.translate('alerts.successfully') +  I18n.translate('action_titles.deleted')
      redirect_to action: 'index'
    else
      flash[:alert] = I18n.translate('alerts.had_errors') + I18n.translate('action_titles.delete')
      respond_with @excuse
    end
  end

  private

  def find_excuse
    if valid_current_school
      @school = get_current_school
      @excuse = Excuse.includes(:school).where(id: params[:id], school_id: @school.id).first
    end
  end

end
