# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class AnnouncementsController < ApplicationController
  load_and_authorize_resource
  def show

  end

  def index
    @announcements = Announcement.order("end_at DESC")

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
    # Date validation can be tricky, so the begin/rescue/end block here is used to confirm that
    # the parameters can be parsed. Because it's not validating the input rather than the resultant
    # database value, it belongs in the controller.
    begin
      @announcement.start_at = Date.strptime(params[:announcement][:start_at], "%m/%d/%Y")
    rescue
      if params[:announcement][:start_at]
        @announcement.errors.add :start_at, " cannot be parsed."
      else
        @announcement.errors.add :start_at, " is required!"
      end
    end

    begin
      @announcement.end_at = Date.strptime(params[:announcement][:end_at], "%m/%d/%Y")
    rescue
      if params[:announcement][:end_at]
        @announcement.errors.add :end_at, " cannot be parsed."
      else
        @announcement.errors.add :end_at, " is required!"
      end
    end

    respond_to do |format|
      if @announcement.save
        format.html { redirect_to announcements_path }
      else
        format.html { render action: :new }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    respond_to do |format|
      if @announcement.update_attributes(params[:announcement])
        format.html { redirect_to announcements_path, notice: "Announcement successfully updated!" }
      else
        format.html { render action: :edit }
      end
    end
  end

  def hide
    ids = [params[:id], *cookies.signed[:hidden_announcement_ids]]
    cookies.permanent.signed[:hidden_announcement_ids] = ids
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end
end
