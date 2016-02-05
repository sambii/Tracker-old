# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class UsersController < ApplicationController

  include UsersHelper

  before_filter :authorize_current_user
  load_and_authorize_resource except: [:create, :update]

  def show
    # # todo - Why are we doing this everytime user goes to home page?
    # remove_school_context
    set_school if enforce_context?
    @user.role_symbols.each do |role|
      if @user.try(role)
        # create role named instance variable (e.g. @teacher) for each role the user has
        eval('@' + role.to_s + " = #{role.to_s.camelize}.find(#{@user.id})")
      end
      Rails.logger.debug("Role: #{role.to_s.pluralize + '/dashboard'}")
    end
    Rails.logger.debug("First Role: #{@user.role_symbols.first.to_s.pluralize}")

    respond_to do |format|
      # go to dashboard corresponding to first role found for the user
      format.html { redirect_to "/#{@user.role_symbols.first.to_s.pluralize}/#{@user.id}" }
      format.js # New UI - view staff member
    end
  end

  def index
    @users = @users.alphabetical
    respond_to do |format|
      format.html
    end
  end


  # New UI
  def new_staff
    @user = User.new
    @user.school_id = current_school_id
    respond_to do |format|
      format.js
    end
  end

  # New UI
  def create
    @user = User.new(params[:user])

    @user.school_id = current_school_id
    @user.set_unique_username
    @user.set_temporary_password

    set_role(@user, 'system_administrator', params['user']['system_administrator']) if params['user']['system_administrator']
    set_role(@user, 'researcher', params['user']['researcher']) if params['user']['researcher']
    set_role(@user, 'school_administrator', params['user']['school_administrator']) if params['user']['school_administrator']
    set_role(@user, 'counselor', params['user']['counselor']) if params['user']['counselor']
    set_role(@user, 'teacher', params['user']['teacher']) if params['user']['teacher']
    set_role(@user, 'student', params['user']['student']) if params['user']['student']
    set_role(@user, 'parent', params['user']['parent']) if params['user']['parent']

    @user.errors.add(:base, "not allowed to create this type of user: #{@user.role_symbols.inspect}") if !can?(:create, @user)

    respond_to do |format|
      if @user.errors.count == 0 && @user.save
        format.js
      else
        flash[:alert] = "ERROR: #{@user.errors.full_messages}"
        format.js
      end
    end
  end


  def edit
    respond_to do |format|
      format.js
    end
  end

  def profile
    respond_to do |format|
      format.html
    end
  end

  def update
    if params[:user][:password].blank? and params[:user][:password_confirmation].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    @user = User.find(params[:id])

    set_role(@user, 'system_administrator', params['user']['system_administrator']) if params['user']['system_administrator']
    set_role(@user, 'researcher', params['user']['researcher']) if params['user']['researcher']
    set_role(@user, 'school_administrator', params['user']['school_administrator']) if params['user']['school_administrator']
    set_role(@user, 'counselor', params['user']['counselor']) if params['user']['counselor']
    set_role(@user, 'teacher', params['user']['teacher']) if params['user']['teacher']
    set_role(@user, 'student', params['user']['student']) if params['user']['student']
    set_role(@user, 'parent', params['user']['parent']) if params['user']['parent']

    @user.errors.add(:base, "not allowed to update this type of user: #{@user.role_symbols.inspect}") if !can?(:update, @user)

    respond_to do |format|
      lname = params[:user][:last_name]
      reload_staff_list = (lname.present? && lname != @user.last_name && lname[0] != @user.last_name[0]) ? true : false
      if @user.errors.count == 0 && @user.update_attributes(params[:user])
        if @user.password and @user.password_confirmation
          Rails.logger.debug("*** change password.")
          if @user.reset_password!(@user.password, @user.password_confirmation)
            @user.temporary_password = nil unless @user.temporary_password == @user.password
            @user.save
            format.html { redirect_to(root_path, :notice => 'Password was successfully updated.') }
          else
            format.html { render :action => "change_password" }
          end
        else
          if params[:commit] == 'update_staff'
            if reload_staff_list
              format.js { render js: "window.location.reload(true);" }
            else
              format.js
            end
          elsif params[:commit] == 'active'
            Rails.logger.debug("*** update active flag.")
            format.js
          else
            Rails.logger.debug("*** update other.")
            format.html { redirect_to(root_path, :notice => 'Profile successfully updated.') }
          end
        end
      else
        Rails.logger.error("ERROR - #{@user.errors.full_messages}")
        flash[:alert] = "ERROR: #{@user.errors.full_messages}"
        if params[:commit] == 'update_staff'
          Rails.logger.debug("*** update staff errors.")
          format.js
        else
          Rails.logger.debug("*** redo change password.")
          format.html { render :action => "change_password" }
        end
      end
    end
  end

  def staff_listing
    # @staff = User.accessible_by(current_ability, User).order(:last_name, :first_name).scoped
    @school = get_current_school
    if @school.has_flag?(School::USER_BY_FIRST_LAST)
      @staff = User.where('teacher=? OR counselor=? OR school_administrator=?', true, true, true).order(:first_name, :last_name).scoped
    else
      @staff = User.where('teacher=? OR counselor=? OR school_administrator=?', true, true, true).order(:last_name, :first_name).scoped
    end
    respond_to do |format|
      if @school.id.present?
        Rails.logger.debug("*** @school.id = #{@school.id}")
        @staff = @staff.where(school_id: @school.id)
        Rails.logger.debug("*** staff count = #{@staff.count}")
        format.html
      else
        @staff
        flash[:alert] = "Please pick a school."
        format.html {redirect_to schools_path}
      end
    end
  end

  # New UI
  # listing of current and previous sections for a staff member
  def sections_list
    user_loaded = nil
    if @user.role_symbols.include?(:teacher)
      user_loaded = Teacher.where(active: [true, false]).find(@user.id)
    end

    @current_sections = []
    @previous_sections = []
    if user_loaded
      @current_sections = user_loaded.sections.order(:position).current
      @previous_sections = user_loaded.sections.order(:position).old
    end

    respond_to do |format|
      format.html
    end
  end

  # Other Methods
  # TODO: Finish this method!
  def set_temporary_password
    @user.set_temporary_password
    @user.save

    respond_to do |format|
      format.js
    end
  end

  def change_password
    @user = current_user

    respond_to do |format|
      format.html
      format.xml { render :xml => @user }
    end
  end

  def account_activity_report
    @users = @users.alphabetical
    respond_to do |format|
      format.html
    end
  end

  # New UI
  # Staff reset passwords from Staff listing via JS
  def security
    @user = User.find(params[:id])
    Rails.logger.debug("*** @user = #{@user.inspect.to_s}")
    respond_to do |format|
      format.js  # render security.js.coffee which renders _security.html.haml
    end
  end

  # new UI HTML get method
  # Bulk Upload Staff (teachers, School Admins, ...)
  # see bulk_update_staff for further processing of file uploaded.
  # stage 1 - gets the filname to upload and is posted to bulk_update_staff
  def bulk_upload_staff
    @errors = Hash.new
    @stage = 1
    @school = get_current_school
    respond_to do |format|
      flash.now[:alert] = 'No current school selected.' if @school.id.blank?
      format.html
    end
  end


  # new UI HTML post method
  # Bulk Update Staff (teachers, School Admins, ...)
  # see bulk_upload_staff which gets the file to upload.
  # stage 2 - reads csv file in and errors found within spreadsheet
  # stage 3 - reads csv file in and errors found against database
  # stage 4 - reads csv file and performs model validation of each record
  # stage 5 - updates records within a transaction - can upload again if errors
  # see app/helpers/users_helper.rb for helper functions
  def bulk_update_staff
    @preview = true if params['preview']
    @stage = 1
    Rails.logger.debug("*** UsersController.bulk_update_staff started")
    @errors = Hash.new
    @error_list = Hash.new
    @school = get_current_school
    @errors[:base] = 'No current school selected.' if @school.id.blank?
    @records = Array.new

    if @errors.count > 0
      Rails.logger.debug("*** @errors: #{@errors.inspect}")
      # don't process, error
    elsif params['file'].blank?
      @errors[:filename] = "Error: Missing Staff Upload File."
    else

      # stage 2
      @stage = 2
      Rails.logger.debug("*** Stage: #{@stage}")
      # no initial errors, process file
      @filename = params['file'].original_filename
      # @errors[:filename] = 'Choose file again to rerun'
      # note: 'headers: true' uses column header as the key for the name (and hash key)
      CSV.foreach(params['file'].path, headers: true) do |row|
        rhash = validate_csv_fields(row.to_hash)
        if rhash[COL_ERROR]
          @errors[:base] = 'Errors exist - see below:' if !rhash[COL_EMPTY]
        end
        @records << rhash if !rhash[COL_EMPTY]
      end  # end CSV.foreach

      # check for file duplicate Student emails and Student IDs (OK for duplicate parent emails)
      # loop through all records
      dup_email_checked = validate_dup_emails(@records)
      @error_list = dup_email_checked[:error_list]
      @records2 = dup_email_checked[:records]
      @errors[:base] = 'Errors exist - see below!!!:' if dup_email_checked[:abort] || @error_list.length > 0

      # stage 3
      @stage = 3
      Rails.logger.debug("*** Stage: #{@stage}")
      # create an array of emails to preload all from database
      emails = Array.new
      @records2.each do |rx|
        emails << rx[COL_EMAIL]
      end
      # get any matching emails in database
      matching_emails = User.where(school_id: @school.id, email: emails)
      if matching_emails.count > 0
        @records2.each_with_index do |rx, ix|
          # check all records following it for duplicated email
          if emails.include?(rx[COL_EMAIL])
            @records2[ix][COL_ERROR] = append_with_comma(@records2[ix][COL_ERROR], 'Email in use.')
            @errors[:base] = 'Errors exist - see below:'
          end
        end
      end # matching_emails.count > 0

      # stage 4
      @stage = 4
      Rails.logger.debug("*** @errors: #{@errors.count}")
      Rails.logger.debug("*** Stage: #{@stage}")

      @records2.each_with_index do |rx, ix|

        staff = build_staff(rx)
        if staff.errors.count > 0 || !staff.valid?
          err = @records2[ix]["error"]
          @records2[ix][COL_ERROR] = append_with_comma(@records2[ix][COL_ERROR], staff.errors.full_messages.join(', '))
          msg_str = "ERROR: #{staff.errors.full_messages}"
          Rails.logger.error(msg_str)
          @errors[:base] = 'Errors exist - see below:'
        end

      end # @records2 loop
    end # end stage 1-4

    if @errors.count == 0 && @error_list.length == 0

      # stage 5
      @stage = 5
    end

    Rails.logger.debug("*** Final Stage: #{@stage}")

    @any_errors = @errors.count > 0 || @error_list.count > 0

    @rollback = false

    # if stage 5 and not preview mode
    # - update records within a transaction
    # - rollback if errors
    respond_to do |format|
      if !@preview && @stage == 5
        begin
          ActiveRecord::Base.transaction do
            @records2.each_with_index do |rx, ix|


              staff = build_staff(rx)
              staff.save!
              @records[ix][COL_SUCCESS] = 'Created'
            end # @records loop
            # raise "Testing report output without update."
          end #transaction
          format.html {render action: 'bulk_update_staff'}
        rescue Exception => e
          msg_str = "ERROR updating database: Exception - #{e.message}"
          @errors[:base] = msg_str
          @rollback = true
          Rails.logger.error(msg_str)
          flash.now[:alert] = 'Errors exist - see below:' if @errors[:base].present?
          format.html {render action: 'bulk_update_staff'}
        end
      elsif @preview && @stage == 5
        # stage 5 preview, show the user the listiong
        flash.now[:alert] = 'Errors exist - see below:' if @errors[:base].present?
        format.html {render action: 'bulk_update_staff'}
      else
        # not stage 5, show user the errors
        flash.now[:alert] = 'Errors exist - see below:' if @errors[:base].present?
        format.html {render action: 'bulk_update_staff'}
      end
    end
  end


  #####################################################################################
  protected

    def set_role(user_in, role, value)
      Rails.logger.debug("*** set_role(#{role}, #{value}")
      if !can?(:update, role.to_s.camelize.constantize)
        Rails.logger.error("ERROR - Not authorized to set #{role.to_s.camelize} role")
        user_in.errors.add(:base, "Not authorized to set #{role.to_s.camelize} role")
      else
        user_in.send(role+'=', value)
      end
    end

end
