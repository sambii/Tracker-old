# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class TeachersController < ApplicationController
  load_and_authorize_resource

  def index
    respond_to do |format|
      format.html
      format.json
    end
  end

  # New UI - Teacher Dashboard
  def show
    @current_sections = @teacher.sections.order(:position).current
    @old_sections     = @teacher.sections.order(:position).old

    current_sect_ids = []
    @teacher.teaching_assignments.each do |ta|
      current_sect_ids << ta.section_id if @teacher.school.school_year_id == ta.section.school_year_id
    end

    # used for both overall student performance and section proficiency bars
    @ratings = SectionOutcomeRating.hash_of_section_outcome_rating_by_section(section_ids: current_sect_ids)

    unique_student_ids = Enrollment.where(section_id: current_sect_ids).pluck(:student_id).uniq
    Rails.logger.debug("*** unique_student_ids = #{unique_student_ids.inspect.to_s}")

    @students = Student.alphabetical.where(id: unique_student_ids)

    @student_ratings = SectionOutcomeRating.hash_of_students_rating_by_section(section_ids: current_sect_ids)

    # recent activity
    @recent10 = Student.where('current_sign_in_at IS NOT NULL AND id in (?)', unique_student_ids).order('current_sign_in_at DESC').limit(10)


    respond_to do |format|
      format.html
      # format.json #?????
    end
  end

  # to be replaced by the new UI User#new_staff
  # Note that creating a new teacher will also create a new user.
  def new
    respond_to do |format|
      format.html
    end
  end

  # to be replaced by the new UI Users#create_staff
  # Note that creating a new teacher will also create a new user.
  def create
    @teacher.set_unique_username
    @teacher.set_temporary_password

    respond_to do |format|
      if @teacher.save
        format.html { redirect_to(@teacher, notice: 'Teacher successfully created!') }
      else
        format.html { render :action => "new" }
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
      if @teacher.update_attributes(params[:teacher])
        format.html { redirect_to @teacher, notice: "Teacher successfully updated!" }
      else
        format.html { render action: "new" }
      end
    end
  end

  def tracker_usage
    # currently for all teacher in only one school
    @school = get_current_school
    @teachers = Teacher.includes(sections: :section_outcomes).where(school_id: @school.id, active: true)
    respond_to do |format|
      format.html
    end
  end

end
