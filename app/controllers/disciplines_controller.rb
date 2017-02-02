# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class DisciplinesController < ApplicationController
  load_and_authorize_resource except: :index

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
      format.html
      format.json
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    respond_to do |format|
        if @discipline.save
          format.html { redirect_to(@discipline, :notice => 'Student was successfully created.') }
        else
          format.html { render :action => "new" }
        end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    respond_to do |format|
      if @discipline.update_attributes(params[:discipline])
        format.html { redirect_to @discipline }
      else
        format.html { render action: "new" }
      end
    end
  end
end
