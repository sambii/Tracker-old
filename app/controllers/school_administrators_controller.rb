# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SchoolAdministratorsController < ApplicationController
  load_and_authorize_resource

  def index
    respond_to do |format|
      format.html
    end
  end
  # New UI - School Administrator Dashboard
  def show

    current_sect_ids = []

    if (@current_user.system_administrator? || @current_user.researcher?)
      @school = @current_school
    else
      @school = School.find(@school_administrator.school_id)
    end
    if @school.id.nil?
      flash[:alert] = 'Missing School'
    else
      @school_year = SchoolYear.find(@school.school_year_id)
      @school_ratings = @school.count_ratings

      @subjects = Subject.where(school_id: @school.id)

      # get subject ratings by various orders
      @subject_ratings = Hash.new
      @subjects.each do |s|
        @current_sections = Section.where(school_year_id: @school.school_year_id, subject_id: s.id)
        @subject_ratings[s.id] = s.count_ratings_plus(section_ids: @current_sections.pluck(:id), school_year_starts_at: @school_year.starts_at)
      end
      @by_date = @subject_ratings.sort_by{|k,v| v[:last_rating_date].to_time}.reverse
      @by_lo_count = @subject_ratings.sort_by{|k,v| (v[:by_count_ratio])}

      @recent10 = User.where('(teacher=? OR counselor=? OR school_administrator=?) AND current_sign_in_at IS NOT NULL AND school_id=?', true, true, true, @school.id).order(:last_name, :first_name).order('current_sign_in_at DESC').limit(10)
    end

    respond_to do |format|
      format.html
      # format.json #?????
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    @school_administrator.set_unique_username
    @school_administrator.set_temporary_password

    respond_to do |format|
      if @school_administrator.save
       format.html { redirect_to(@school_administrator, :notice => 'School administrator was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end
end
