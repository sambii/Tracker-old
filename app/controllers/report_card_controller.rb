# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class ReportCardController < ApplicationController
	# load_and_authorize_resource :report_card_request, parent: false

	def new
	end

  def forward
    Rails.logger.debug "*** ReportCardController.forward started"
    begin
      @report_card_request = ReportCardRequest.new

      raise BlankEmailException  if current_user.email.blank?
      raise UserInvalidException if current_user.invalid?

      school_id = get_current_school
      Rails.logger.debug "*** school_id: #{school_id}"
      school = School.find(school_id)
      Rails.logger.debug "*** school: #{school.inspect}"
      email = current_user.email
      Rails.logger.debug "*** email: #{email}"
      full_name = current_user.full_name
      Rails.logger.debug "*** full_name: #{full_name}"
      Rails.logger.debug("*** params[:grade_level] = #{params[:grade_level]}")
      grade = params[:grade_level]
      Rails.logger.debug "*** grade: #{grade}"
      url = request.protocol+request.host_with_port
      Rails.logger.debug("*** url: #{url}")

      # create dummy report_card_request to get this to work
      @report_card_request.grade_level = grade


      Rails.logger.debug("*** start ReportCardProcessor.new")
      p = ReportCardProcessor.new(school_id,grade,email,full_name,url)
      if p.generate
        ReportCardMailer.delay(priority: 0).request_recieved_email(email,grade,full_name,school)
        flash[:notice] = 'Report card has been queued for processing'
        # render 'new'
      else
        flash[:alert] = 'Request Submission Failed!'
        # render 'new'
      end
    rescue BlankEmailException
      Rails.logger.debug("*** BlankEmailException")
      @report_card_request.errors.add(:base, "#{current_user.full_name}, we need a registered email for you before you can request report cards")
      flash[:alert] = 'Request Submission error, Blank Email Exception!'
      # render 'new'
    rescue UserInvalidException
      Rails.logger.debug("*** UserInvalidException")
      @report_card_request.errors.add(:user, 'is invalid')
      flash[:alert] = 'Request Submission error, Invalid User Exception!'
      # render 'new'
    rescue Exception => e
      Rails.logger.debug("*** Exception #{e.message}")
      @report_card_request.errors.add(:base,"#{e}")
      flash[:alert] = "Request Submission error, Exception: #{e.message}"
      # render 'new'
    end
    respond_to do |format|
      format.html {redirect_to new_generate_path}
    end
  end

  # process by old report card form - to be removed
	def create
    @grade_level = params[:report_card_request][:grade_level]
    begin
      raise BlankEmailException  if current_user.email.blank?
      raise UserInvalidException if current_user.invalid?

      school_id = current_user.school_id
      school_instance = School.find(school_id)
      email = current_user.email
      full_name = current_user.full_name
      grade = params[:report_card_request][:grade_level]
      url = request.protocol+request.host_with_port

      p = ReportCardProcessor.new(school_id,grade,email,full_name,url)
      if p.generate
        ReportCardMailer.delay(priority: 0).request_recieved_email(email,grade,full_name,school_instance)
        flash[:notice] = 'Report card has been queued for processing'
        render 'new'
      else
        flash[:alert] = 'Request Submission Failed!'
        render 'new'
      end
    rescue BlankEmailException
      @report_card_request.errors.add(:base, "#{current_user.full_name}, we need a registered email for you before you can request report cards")
      render 'new'
    rescue UserInvalidException
      @report_card_request.errors.add(:user, 'is invalid')
      render 'new'
    rescue Exception => e
      @report_card_request.errors.add(:base,"#{e}")
      render 'new'
    end
 end
end

class BlankEmailException < StandardError
end

class UserInvalidException < StandardError
end
