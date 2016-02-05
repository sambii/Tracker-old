# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class DisciplinesController < ApplicationController
  load_and_authorize_resource except: :index

  def show
    respond_to do |format|
      format.html
    end
  end

  def index
    @disciplines = Discipline.order(:name).accessible_by(current_ability, :index)
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
