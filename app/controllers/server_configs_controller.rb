# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class ServerConfigsController < ApplicationController

  # New UI - System Administrator Dashboard
  def show
    authorize! :sys_admin_links, User
    server_configs = ServerConfig.all
    if server_configs.count == 0
      err_msg = "ERROR: Server Config did not exist, Default one Created, Please Edit! "
      Rails.logger.error(err_msg)
      @server_config = ServerConfig.new
      @server_config.id = 1 # make sure id is 1 - ensure only one exists and is found by ID 1
      @server_config.save
      flash[:alert] = err_msg
    elsif server_configs.count > 1
      err_msg = "ERROR: too many Server Config records.  Must be fixed manually !!! "
      Rails.logger.error(err_msg)
      @server_config = server_configs.first
      flash[:alert] = err_msg
    else
      @server_config = server_configs.first
    end
    respond_to do |format|
      format.html
    end
  end

  def edit
    authorize! :sys_admin_links, User
    server_configs = ServerConfig.all
    if server_configs.count == 0
      err_msg = "ERROR: Server Config did not exist, Default one Created, Please Edit! "
      Rails.logger.error(err_msg)
      @server_config = ServerConfig.new
      @server_config.id = 1 # make sure id is 1 - ensure only one exists and is found by ID 1
      @server_config.save
      flash[:alert] = err_msg
    elsif server_configs.count > 1
      err_msg = "ERROR: too many Server Config records.  Must be fixed manually !!! "
      Rails.logger.error(err_msg)
      @server_config = server_configs.first
      flash[:alert] = err_msg
    else
      @server_config = server_configs.first
    end
    respond_to do |format|
      format.html
    end
  end

  def update
    authorize! :sys_admin_links, User
    @server_config = ServerConfig.first
    respond_to do |format|
      if @server_config.update_attributes(params[:config])
        format.html { render action: :show }
      else
        format.html { render action: :add_edit }
      end
    end
  end

end
