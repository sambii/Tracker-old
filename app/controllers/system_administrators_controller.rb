# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SystemAdministratorsController < ApplicationController

  load_and_authorize_resource

  # New UI - System Administrator Dashboard
  def show
    @model_school = School.where(acronym: 'MOD').first
    @school = get_current_school 
    @schools = School.accessible_by(current_ability).order('name')
    respond_to do |format|
      format.html
    end
  end

end
