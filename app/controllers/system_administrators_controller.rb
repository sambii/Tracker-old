# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SystemAdministratorsController < ApplicationController

  # New UI - System Administrator Dashboard
  def show
    authorize! :sys_admin_links, User
    @system_administrator = User.find(params[:id])
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

  def system_users
    authorize! :sys_admin_links, User
    @model_school = School.find(1)
    @system_users = User.where("users.system_administrator = ? OR users.researcher = ?", true, true)
    Rails.logger.debug("*** users: #{@system_users.inspect}")
    respond_to do |format|
      format.html
    end
  end

  def new_system_user
    authorize! :sys_admin_links, User
    @user = User.new
    respond_to do |format|
      format.js
    end
  end

  def create_system_user
    authorize! :sys_admin_links, User
    @model_school = School.find(1)
    @user = User.new

    if params['role'] == 'system_administrator'
      set_role(@user, 'system_administrator', true) 
      set_role(@user, 'researcher', false) 
    elsif params['role'] == 'researcher'
      set_role(@user, 'researcher', true)
      set_role(@user, 'system_administrator', false)
    else
      @user.errors.add(:base, 'Role is required!')
    end
    @user.assign_attributes(params[:user])
    @user.set_unique_username
    @user.set_temporary_password
    if params[:user][:first_name].blank?
      @user.errors.add(:first_name, "Given/First Name is required")
    end
    if params[:user][:last_name].blank?
      @user.errors.add(:last_name, "Family/Last Name is required")
    end
    if params[:user][:email].blank? && @model_school.has_flag?(School::USERNAME_FROM_EMAIL)
      @user.errors.add(:email, "Email is required")
    end

    if @user.errors.count == 0
      if @user.save
         # deliver after successful save
        UserMailer.welcome_system_user(@user, get_server_config).deliver
      end
    end

    respond_to do |format|
      format.js
    end

  end

  def edit_system_user
    authorize! :sys_admin_links, User
    @user = User.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def update_system_user
    authorize! :sys_admin_links, User
    @model_school = School.find(1)
    @user = User.find(params[:id])

    if params['role'] == 'system_administrator'
      set_role(@user, 'system_administrator', true) 
      set_role(@user, 'researcher', false) 
    elsif params['role'] == 'researcher'
      set_role(@user, 'researcher', true)
      set_role(@user, 'system_administrator', false) 
    end
    @user.assign_attributes(params[:user])
    respond_to do |format|
      if params[:user][:email].blank? && @model_school.has_flag?(School::USERNAME_FROM_EMAIL)
        @user.errors.add(:email, "email is required")
        Rails.logger.error("*** @user.errors: #{@user.errors.inspect}")
        format.js
      else
        if @user.errors.count == 0
          @user.update_attributes(params[:user])
          Rails.logger.error("*** after update_attributes @user.errors: #{@user.errors.inspect}")
        else
          Rails.logger.error("*** no update_attributes @user.errors: #{@user.errors.inspect}")
        end
        format.js
      end
    end
  end

  #####################################################################################
  protected

    # cloned from users_controller !!!
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
