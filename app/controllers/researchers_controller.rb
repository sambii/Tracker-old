# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class ResearchersController < ApplicationController
  load_and_authorize_resource

  # New UI
  # Researcher Dashboard Page
  #   GET "/researchers/#"
  #   Parameters: {"id"=>"#"}
  #   Rendered researcers/show.html.haml within layouts/application
  def show
    respond_to do |format|
      format.html
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    @researcher.set_temporary_password

    respond_to do |format|
      if @researcher.save
        format.html { redirect_to(current_user, :notice => @researcher.full_name + " successfully created!") }
      else
        format.html { render :action => :new }
      end
    end
  end

end
