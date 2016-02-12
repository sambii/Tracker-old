# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class ParentsController < ApplicationController
  load_and_authorize_resource

  # def show
  #   Rails.logger.debug("*** @parent = #{@parent.inspect.to_s}")
  #   Rails.logger.debug("*** @parent.student = #{@parent.student.inspect.to_s}")
  #   respond_to do |format|
  #     format.json
  #     format.html { redirect_to(parent_url(@parent.child_id)) }
  #   end
  # end

  # New UI
  # Student Dashboard page
  #   GET "/parents/#"
  #   Parameters: {"id"=>"#"}
  #   Rendered parents/show.html.haml within layouts/application
  #      - uses student/_dashboard.html.haml
  def show
    @student = Student.find(@parent.child_id)
    @active_enrollments = Enrollment.includes(:section).current.where(student_id: @student)
    current_sect_ids = @active_enrollments.pluck(:section_id)
    @ratings = @student.hash_of_section_outcome_rating_counts(section_ids: current_sect_ids)
    @e_over_cur = @student.overall_current_evidence_ratings
    @e_weekly_cur = @student.overall_current_evidence_ratings 1.week.ago
    @missing = @student.missing_evidences_by_section

    respond_to do |format|
      format.html
    end
  end

  def update
    @school = get_current_school
    respond_to do |format|
      parent_status = @parent.update_attributes(params[:parent])
      if parent_status
        if params[:parent][:password].present? && params[:parent][:temporary_password].present?
          UserMailer.changed_user_password(@parent, @school, get_server_config).deliver # deliver after save
        end
        format.js
      else
        format.js { render js: "alert('Parent could not be updated.');" }
      end
    end
  end
end
