# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
# various methods for the UI to make ajax calls to.
# provides UI access to the server.
class UiController < ApplicationController

  respond_to :js

  def save_cell_size
    Rails.logger.debug("*** save_cell_size - params = #{params.inspect.to_s}")
    session[:cell_size] = params[:cell_size]
    render nothing: true
  end

  def save_toolkit
    Rails.logger.debug("*** save_toolkit - params = #{params.inspect.to_s}")
    session[:toolkit] = params[:toolkit]
    render nothing: true
    Rails.logger.debug("*** session[:toolkit] = #{session[:toolkit]}")
  end

  def logged_in?
    current_user.present?
  end

end
