# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class HomeController < ApplicationController
  # Not hooked up to a database table / ActiveRecord model like the other controllers. Used to serve
  # semi-static pages that still need some server information.

  # RESTful Methods
  # This page is found at the root of the domain (https://tracker.parloproject.org/)
  def index
    respond_to do |format|

      # Redirect the user to his or her dashboard if signed in. Otherwise, display the home page.
      if user_signed_in?
        format.html { redirect_to view_context.user_dashboard_path(current_user) }
      else
        format.html
      end
    end
  end

  protected
    def set_current_user
      return 0
    end
end
