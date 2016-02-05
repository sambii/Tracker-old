# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class TeachingResourcesController < ApplicationController
  def index
    @disciplines = Discipline.include_teaching_resources
  end

  def new
    @teaching_resource  = TeachingResource.new
    @disciplines        = Discipline.order(:name).all
  end

  def create
    @teaching_resource = TeachingResource.new(params[:teaching_resource])

    respond_to do |format|
      if @teaching_resource.save
        format.html { redirect_to teaching_resources_path, :message => "Teaching resource successfully added!" }
      else
        format.html { render :action => :new }
      end
    end
  end
end
