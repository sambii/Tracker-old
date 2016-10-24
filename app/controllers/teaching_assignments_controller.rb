# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class TeachingAssignmentsController < ApplicationController

  # New UI
  # teaching assignment bulk entry page
  def enter_bulk
    Rails.logger.debug("*** enter_bulk")
    authorize! :read, User # force login if not logged in
    @errors = Hash.new
    num_items = prep_for_bulk_view
        Rails.logger.debug("*** num_items: #{num_items}")
    respond_to do |format|
      if num_items == 0
          flash[:alert] = 'No sections to assign teachers to.'
         format.html { redirect_to subjects_path }
      else
        format.html
      end
    end
  end


  # New UI
  # teaching assignment bulk entry update page
  def update_bulk
    Rails.logger.debug("*** update_bulk")
    authorize! :read, User # force login if not logged in
    @errors = Hash.new
    @school = get_current_school
    @errors[:base] = add_error(@errors[:base], 'Need to assign school.') if @school.id.blank?
    respond_to do |format|
      begin
        ta_params = params['teaching_assignment_attributes']
        if ta_params
          ActiveRecord::Base.transaction do
            ta_params.each do |subj_id, sect_tas|
              sect_tas.each do |sect_id, t_id|
                if t_id.present?
                  raise("Section not in this school!") if Section.where(id: sect_id, school_year_id: @school.school_year_id).count == 0
                  raise("Teacher not in this school!") if Teacher.where(id: t_id, school_id: @school.id).count == 0
                  ta = TeachingAssignment.new
                  ta.section_id = sect_id
                  ta.teacher_id = t_id
                  raise("Errors creating teaching assignment: #{ta.errors.full_messages}") if !ta.save
                end
              end
            end
            # raise "Successful Test cancelled"
          end #transaction
        end
        num_items = prep_for_bulk_view
        if num_items == 0
          flash[:notify] = 'No more sections to assign teachers to.'
          format.html { redirect_to subjects_path }
        else
          format.html
        end
      rescue Exception => e
        msg_str = "ERROR: Exception - #{e.message}"
        @errors[:base] = add_error(@errors[:base], msg_str)
        Rails.logger.error(msg_str)
        flash[:alert] = msg_str
        num_items = prep_for_bulk_view
        # if num_items == 0
        #   flash[:alert] = 'No sections to assign teachers to.'
        # always redirect to subjects listing page
          format.html { redirect_to subjects_path }
        # else
        #   format.html
        # end
      end # begin
    end # respond_to
  end

  #####################################################################################
  protected

  def add_error(prior_errors, new_error)
    resp = (prior_errors.present? ? prior_errors+', '+new_error : new_error)
  end

  def prep_for_bulk_view
    @school = get_current_school
    # required @errors = Hash.new to predefined
    all_subject_ids = Subject.where(school_id: current_school_id).pluck(:id)
    all_section_ids = Section.where(subject_id: all_subject_ids).pluck(:id)
    assigned_subject_section_ids = TeachingAssignment.where(section_id: all_section_ids).pluck(:section_id)
    unassigned_subject_section_ids = all_section_ids - assigned_subject_section_ids
    @disciplines = Discipline.includes(subjects: {sections: :teachers }).where('sections.id in (?)', unassigned_subject_section_ids).order('disciplines.name, subjects.name, sections.line_number')
    # @teachers = Teacher.where(school_id: current_school_id)
    if @school.has_flag?(School::USER_BY_FIRST_LAST)
      @teachers = Teacher.where(school_id: current_school_id).accessible_by(current_ability).order(:first_name, :last_name)
    else
      @teachers = Teacher.where(school_id: current_school_id).accessible_by(current_ability).order(:last_name, :first_name)
    end
    @errors[:base] = add_error(@errors[:base], 'Need to assign school.') if @school.id.blank?
    @errors[:base] = add_error(@errors[:base], 'Cannot run Teacher Assignment Bulk Entry, all sections have a teacher assigned') if unassigned_subject_section_ids == 0
    return unassigned_subject_section_ids.count
  end

end
