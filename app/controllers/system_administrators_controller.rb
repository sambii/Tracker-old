# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SystemAdministratorsController < ApplicationController

  load_and_authorize_resource

  # New UI - System Administrator Dashboard
  def show
    @model_school = School.includes(:school_year).find(1)
    @school = get_current_school 
    @schools = School.includes(:school_year).accessible_by(current_ability).order('name')
    respond_to do |format|
      format.html
    end
  end

  def system_maintenance
    authorize! :sys_admin_links, User
    respond_to do |format|
      format.html
    end
  end

end
