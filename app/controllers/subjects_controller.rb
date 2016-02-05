# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SubjectsController < ApplicationController
  load_and_authorize_resource
  skip_before_filter :get_referrer, only: :update_subject_outcomes

  def index
    # needs to be optimized for page load (takes 1.5 sec)
    # @subjects = Subject.where(school_id: current_school_id).order({discipline: :name}, :name)  #.includes(sections: {teaching_assignments: :teacher})
    begin
      @school = get_current_school
      school_year_id = @school.school_year_id
      @sections = Section.where school_year_id: @school.school_year_id
    rescue
      @sections = []
    end
    # note this does not preread teaching assignments
    # @disciplines = Discipline.includes(subjects: {sections: {teachers: :teaching_assignments} }).where(subjects: {school_id: current_school_id}).order('disciplines.name, subjects.name, sections.line_number')
    @disciplines = Discipline.includes(subjects: {sections: :teachers }).where(subjects: {school_id: current_school_id}).order('disciplines.name, subjects.name, sections.line_number')

    respond_to do |format|
      format.html
      format.json
    end
  end

  def list_editable_subjects
    if params[:school_id]
      @subjects = Subject.where(school_id: current_school_id).includes(school: :school_years).order(:starts_at)
    end

    respond_to do |format|
      format.html
    end
  end

  def show
    @school = get_current_school
    @school_year = SchoolYear.find(@school.school_year_id)

    @current_sections = Section.where(school_year_id: @school.school_year_id, subject_id: @subject.id)
    # @current_sections = @subject.sections.current
    @previous_sections = @subject.sections.old

    @subject_rating = @subject.count_ratings_plus(section_ids: @current_sections.pluck(:id), school_year_starts_at: @school_year.starts_at)


    @section_ratings = @subject.count_section_ratings_plus(section_ids: @current_sections.pluck(:id), school_year_starts_at: @school_year.starts_at, skip_zeros: true)

    @by_date = @section_ratings.sort_by{|k,v| v[:last_rating_date].to_time}.reverse
    @by_lo_count = @section_ratings.sort_by{|k,v| v[:by_count_ratio]}
    @by_nyp_pct = @section_ratings.sort_by{|k,v| v[:by_nyp_ratio]}.reverse

    ua = User.arel_table
    unique_staff_ids = User.where(
      ua[:school_id].eq(@school.id).and(
        ua[:school_administrator].eq(true).or(
        ua[:teacher].eq(true)).or(
        ua[:counselor].eq(true))
      )
    ).pluck(:id)
    @recent10 = User.where('current_sign_in_at IS NOT NULL AND id in (?)', unique_staff_ids).order('current_sign_in_at DESC').limit(10)

    respond_to do |format|
      format.html
    end
  end

  def new
    @school = get_current_school
    @subjects = Subject.where(school_id: @school.id)
    @teachers = Teacher.where(school_id: @school.id, active: true)
    @disciplines = Discipline.order(:name)
    respond_to do |format|
      format.html # new.html.erb
      # format.xml  { render :xml => @student }   # what is this for ???
      format.js
    end
  end

  def create
    @school = get_current_school
    @subjects = Subject.where(school_id: @school.id)
    @teachers = Teacher.where(school_id: @school.id, active: true)
    @disciplines = Discipline.all
    respond_to do |format|
      saved = @subject.save
      @subject.errors.add(:discipline_id, I18n.translate('errors.cant_be_blank')) if !@subject.discipline_id # to get error onto form
      # @subject.errors.add(:subject_manager_id, I18n.translate('errors.cant_be_blank')) if !@subject.subject_manager_id # to get error onto form
      if saved && @subject.errors.count == 0
        format.html { redirect_to(@subject.school, :notice => 'Subject was successfully created.') }
        format.js
      else
        format.html { render :action => "new" }
        format.js
      end
    end
  end

  def edit
    @school = get_current_school
    @subjects = Subject.where(school_id: @school.id)
    @teachers = Teacher.where(school_id: @school.id, active: true)
    @disciplines = Discipline.all
    respond_to do |format|
      format.html
      format.js
    end
  end

  # new UI
  # Edit Learning Outcomes (add/edit subject outcomes):
  # - subjects/#/edit_subject_outcomes - edit button on sections/#/new_section_outcome
  def edit_subject_outcomes
    @subject.subject_outcomes.build if @subject.subject_outcomes.length == 0

    respond_to do |format|
      format.html
      format.js
    end
  end

  def update_subject_outcomes
    params[:subject].slice!(:subject_outcomes_attributes)

    respond_to do |format|
      if @subject.update_attributes(params[:subject])
        format.html { redirect_to session[:return_to] }
      else
        format.html { render action: "edit_subject_outcomes" }
      end
    end
  end

  def update
    @school = get_current_school
    @subjects = Subject.where(school_id: @school.id)
    @teachers = Teacher.where(school_id: @school.id, active: true)
    @disciplines = Discipline.all
    respond_to do |format|
      updated = @subject.update_attributes(params[:subject])
      @subject.errors.add(:discipline_id, I18n.translate('errors.cant_be_blank')) if !@subject.discipline_id # to get error onto form
      if updated && @subject.errors.count == 0
        format.html { redirect_to @subject }
        format.js
      else
        format.html { render action: "edit" }
        format.js
      end
    end
  end

  # New UI
  # Generate Reports - Proficiency Bars by Subject (in subject name order)
  def proficiency_bars
    @school = get_current_school
    @school_year = SchoolYear.find(@school.school_year_id)
    @subjects = Subject.where(school_id: @school.id)

    # get subject ratings by various orders
    @subject_ratings = Hash.new
    @subjects.each do |s|
      @current_sections = Section.where(school_year_id: @school.school_year_id, subject_id: s.id)
      @subject_ratings[s.id] = s.count_ratings_plus(section_ids: @current_sections.pluck(:id), limit: 10)
    end
    # note hash is sorted using array, so hash is returned as an array (with two arguments)
    # e.g. @by_date.each do |srd_k, srd_v|
    @by_date = @subject_ratings.sort_by{|k,v| v[:subject].name}
    @school_ratings = @school.count_ratings
  end

  # New UI
  # Generate Reports - Progress Meters by Subject (in subject name order)
  def progress_meters
    @school = get_current_school
    @school_year = SchoolYear.find(@school.school_year_id)
    @subjects = Subject.where(school_id: @school.id)

    # get subject ratings by various orders
    @subject_ratings = Hash.new
    @subjects.each do |s|
      @current_sections = Section.where(school_year_id: @school.school_year_id, subject_id: s.id)
      @subject_ratings[s.id] = s.count_ratings_plus(section_ids: @current_sections.pluck(:id), limit: 10)
    end
    # note hash is sorted using array, so hash is returned as an array (with two arguments)
    # e.g. @by_date.each do |srd_k, srd_v|
    @by_lo_count = @subject_ratings.sort_by{|k,v| v[:rated_los_count]/v[:all_los_count]}.reverse
  end


end
