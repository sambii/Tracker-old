# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class DisciplinesController < ApplicationController

  def show
    @subjects = Subject.where(discipline_id: params[:id]).includes(:school).order('schools.acronym, subjects.name')
    respond_to do |format|
      format.html
    end
  end

  def index
    @disciplines = Discipline.order(:name).all
    authorize! :read, Discipline # ensure redirect to login page on timeout
    respond_to do |format|
      format.html # This response is used in Evidence Type Maintenance in New UI
      format.json # This response is used by forms in old UI?
    end
  end

  def new
    @discipline = Discipline.new
    authorize! :update, @discipline # only let maintainers do these things
    respond_to do |format|
      format.js{ render action: :add_edit }
    end
  end

  def create
    @discipline = Discipline.new(params[:discipline])
    authorize! :update, @discipline # only let maintainers do these things
    if @discipline.save
      flash[:notice] = I18n.translate('alerts.successfully') +  I18n.translate('action_titles.created')
    else
      flash[:alert] = I18n.translate('alerts.had_errors') + I18n.translate('action_titles.create')
    end
    respond_to do |format|
      format.js { render action: :saved }
    end
  end

  def edit
    @discipline = Discipline.find(params[:id])
    authorize! :update, @discipline # only let maintainers do these things
    respond_to do |format|
      format.js{ render action: :add_edit }
    end
  end

  def update
    @discipline = Discipline.find(params[:id])
    authorize! :update, @discipline # only let maintainers do these things
    if @discipline.update_attributes(params[:discipline])
      flash[:notice] = I18n.translate('alerts.successfully') +  I18n.translate('action_titles.updated')
    else
      flash[:alert] = I18n.translate('alerts.had_errors') + I18n.translate('action_titles.update')
    end
    respond_to do |format|
      format.js { render action: :saved }
    end
  end
end
