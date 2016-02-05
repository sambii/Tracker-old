# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class CounselorsController < ApplicationController
  load_and_authorize_resource

  def index
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
    @counselor.set_unique_username    # Inherited from the User model.
    @counselor.set_temporary_password # Inherited from the User model.

    respond_to do |format|
      if @counselor.save
       format.html { redirect_to(@counselor, :notice => 'Counselor was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end
end
