# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SchoolsController < ApplicationController

  load_and_authorize_resource
  before_filter :remove_params, only: [:update]

  # RESTful Methods
  def show
    template = "schools/show"
    template = "schools/reports/#{params[:report]}" if params[:report]

    if template == "schools/show"
      @school = School.includes(students: {enrollments: {section: [:subject, teaching_assignments: :teacher]}}).find(params[:id])
      set_school_context
    else
      for_subgroup_proficiencies
    end

    respond_to do |format|
      # when send to school page from no current school error, go to last page
      # todo - review this flow, maybe show should not be used here.
      if template == "schools/show"
        Rails.logger.debug("*** return_to: #{session[:return_to]}")
        Rails.logger.debug("*** this_original_url: #{session[:this_original_url]}")
        Rails.logger.debug("*** last_original_url: #{session[:last_original_url]}")
        format.html { redirect_to session[:last_original_url] }
      else
        format.html { render template }
      end
      format.pdf do
        response.headers['Accept-Ranges'] = 'none'
        response.headers['Cache-Control'] = 'private, max-age=0, must-revalidate'
        response.headers['Pragma']        = 'public'
        response.headers['Expires']       = '0'
        render template
      end
    end
  end

  def index
    respond_to do |format|
      format.html
      format.json
    end  # end respond_to
  end  # end index

  # new UI, new school is now a popup
  def new
    respond_to do |format|
      begin
        @state = 'show_school_form'
        @model_school = get_model_school('MOD')
        @school_year = get_school_year(@school, @model_school)
        if @model_school
          # copy default field values from model school to new school
          @school.marking_periods = @model_school.marking_periods
          @school.subsection = @model_school.subsection
          @school.grading_algorithm = @model_school.grading_algorithm # not used
          @school.grading_scale = @model_school.grading_scale # not used
          @school.flags = @model_school.flags
        end
        format.js
      rescue Exception => e
        msg_str = "ERROR: Exception - #{e.message}"
        @school.errors.add(:base, msg_str)
        Rails.logger.error(msg_str)
        flash[:alert] = msg_str
        format.js
      end  # end begin
    end  # end respond_to
  end  #end new

  # new UI, create school is now a popup, but good update response back School listing HTML (page refresh)
  def create
    respond_to do |format|
      begin
        @state = 'show_school_form'
        @model_school = get_model_school('MOD')
        @school_year = get_school_year(@school, @model_school)
        ActiveRecord::Base.transaction do
          if @school.save
            # copy subjects and LOs from Model school to new school
            set_school_year_record(@school_year, params[:school_year])
            # only copy subjects and learning outcomes if this is not the model school
            if @model_school && params[:school][:acronymn] != 'MOD'
              school_subjects = Subject.where(school_id: @school.id)
              fail("Subjects already exist for new school") if school_subjects.count > 0
              school_sections = Section.where(school_year_id: @school.school_year_id)
              fail("Sections already exist for new school") if school_sections.count > 0
              copy_subjects(@model_school, @school)
              format.js { render js: "window.location.reload();", notice: "School was successfully created" }
            end
          else
            format.js { render :action => "new", alert: "Errors creating school: #{@school.errors.full_messages}" }
          end
        end #transaction
      rescue Exception => e
        msg_str = "ERROR: Exception - #{e.message}"
        @school.errors.add(:base, msg_str)
        Rails.logger.error(msg_str)
        format.js { render :action => "new", alert: msg_str }
      end  # end begin
    end  # end respond_to
  end  # end create

  # new UI, edit school is now a popup
  def edit
    # todo - pull this out into a separate action!
    if params[:template]
      template = "edit_#{params[:template]}"
      @school = School.includes(students: :first_enrollment).find(params[:id]) if template == "edit_student_subsections"
      respond_to do |format|
        format.html { render template }
      end
    else
      template = "edit"
      respond_to do |format|
        begin
          @state = 'show_school_form'
          @model_school = get_model_school('MOD')
          @school_year = get_school_year(@school, @model_school)
          format.js
        rescue Exception => e
          msg_str = "ERROR: Exception - #{e.message}"
          @school.errors.add(:base, msg_str)
          Rails.logger.error(msg_str)
          flash[:alert] = msg_str
          format.js
        end  # end begin
      end  # end respond_to
    end
  end

  # new UI, update school is now a popup, but good update response back is HTML
  def update
    respond_to do |format|
      begin
        @state = 'show_school_form'
        @model_school = get_model_school('MOD')
        @school_year = get_school_year(@school, @model_school)
        ActiveRecord::Base.transaction do
          if @school.update_attributes(params[:school])
            set_school_year_record(@school_year, params[:school_year])
            # don't copy of subjects and learning outcomes on update
            # this will be done on the subjects sections listing
            Rails.logger.debug("*** School was successfully updated.")
            format.js { render js: "window.location.reload();", notice: "School was successfully updated" }
          else
            flash[:alert] = "Errors updating school: #{@school.errors.full_messages}"
            format.js
          end
        end #transaction
      rescue Exception => e
        msg_str = "ERROR: Exception - #{e.message}"
        @school.errors.add(:base, msg_str)
        Rails.logger.error(msg_str)
        flash[:alert] = msg_str
        format.js
      end
    end
  end

  # new UI, add/update subjects and LOs from Model School (for new year rollover)
  # - note deactivate subject or subject outcomes not possible at this point
  # - possible temporary solution to put zzz in front of descriptions (note add zzz to dup check!)
  # NOTE: this is untested code
  def new_year_rollover
    respond_to do |format|
      begin
        if (params[:id])
          new_school = School.find(params[:id])
        else
          fail 'Missing school ID'
        end
        model_schools = School.where(acronym: 'MOD')

        rollover_school_year(new_school)
        # Copy subjects and learning outcomes from model school if it exists.
        if model_schools.count == 1
          copy_subjects(model_schools.first, @school)
          format.html { redirect_to( schools_path, notice: "School year was successfully rolled over.") }
        else
          format.html { redirect_to( schools_path, notice: 'School year was successfully rolled over (without Model School LOs).') }
        end

      rescue Exception => e
        Rails.logger.error("ERROR in School.new_year_rollover: Exception #{e.message}")
        format.html { redirect_to( schools_path, alert: "Error on School Year rollover: #{e.message}") }
      end
    end
  end

  protected

    def set_school_context
      if current_user.system_administrator? || current_user.researcher?
        session[:school_context] = @school.id
        set_current_school
      end
    end

    def get_model_school(acronym)
      model_schools = School.where(acronym: acronym)
      if model_schools.count == 1
        return(model_schools.first)
      else
        return nil
      end
    end

    def get_school_year(school, model_school)
      if school.school_year
        return school.school_year
      else
        school_year = SchoolYear.new
        if model_school.present? && model_school.school_year.present?
          school_year.starts_at = model_school.school_year.starts_at
          school_year.ends_at = model_school.school_year.ends_at
          school_year.name = model_school.name
          return school_year
        elsif school.id == model_school.id
          # editing the model school without a school year
          return school_year
        else
          return nil
        end
      end
    end

    # new UI school create or update the school year record
    # must rescue exceptions when calling this.
    def set_school_year_record(school_year, params)

      # attach school to school_year record
      school_year.school_id = @school.id if school_year.school_id.blank?
      fail("invalid school id for school year") if school_year.school_id != @school.id

      # create or update the start and end dates of the school year (should not be used for rollover)
      begin
        if params[:start_yyyy] && params[:start_mm]
          # create starts_at year and month ( with the leading zeros removed) for the first day of the month
          school_year.starts_at = Date.new(Integer(params[:start_yyyy]), Integer(params[:start_mm].sub(/^[0]*/, '')), 1)
        end
        if params[:end_yyyy] && params[:end_mm]
          # create ends_at using year and month params ( with the leading zeros removed) for the last day of the month
          school_year.ends_at = Date.new(Integer(params[:end_yyyy]), Integer(params[:end_mm].sub(/^[0]*/, '')), 1)
        end
        school_year.name = "#{school_year.starts_at.year}-#{school_year.ends_at.year}"
      rescue Exception => e
        err_str = "ERROR: invalid start or end date: Exception #{e.message}"
        Rails.logger.error(err_str)
        fail(err_str)
      end

      # save the school_year record (create or update)
      if !school_year.save
        err_str = "ERROR: creating school year: Exception #{e.message}"
        Rails.logger.error(err_str)
        fail(err_str)
      end

      # attach school_year to school as current school year if not already.
      if @school.school_year_id.blank? && school_year.id.present?
        @school.school_year_id = school_year.id
        if !@school.save
          err_str = "ERROR: updating school with new school year record: Exception #{e.message}"
          Rails.logger.error(err_str)
          fail(err_str)
        end
      end

    end

    # new UI school rollover the school year record
    # must rescue exceptions when calling this.
    def rollover_school_year(school)

      # ensure current school year is valid
      fail("invalid school id for school year") if school.school_year.school_id != school.id

      # make sure next school year record doesn't exist already
      old_school_year_record = school.school_year
      begin_year = old_school_year_record.ends_at.year
      end_year = begin_year + 1
      year_name = "#{begin_year}-#{end_year}"
      next_year_records = School.where(name: year_name)
      fail("next year record already exists") if next_year_records.count > 0

      # create the new school year record for rollover
      begin
        school_year = SchoolYear.new
        school_year.school_id = school.id
        school_year.name = year_name
        # start and end dates same as last year, except year increased by 1
        school_year.starts_at = Date.new(begin_year, old_school_year_record.starts_at.mon, 1)
        school_year.ends_at = Date.new(end_year, old_school_year_record.ends_at.mon, old_school_year_record.ends_at.mday)
        school_year.save
      rescue Exception => e
        err_str = "ERROR: creating next school year: Exception #{e.message}"
        Rails.logger.error(err_str)
        fail(err_str)
      end

      # update current school year
      if school_year.id.present?
        school.school_year_id = school_year.id
        if !school.save
          err_str = "ERROR: updating school with next school year record: Exception #{e.message}"
          Rails.logger.error(err_str)
          fail(err_str)
        end
      end

    end


    # new UI school rollover process - copy subjects from Model school
    # must rescue exceptions when calling this.
    # NOTE: this is untested for rollover (only tested for new school create)
    def copy_subjects(model_school, new_school)
      matches = Array.new

      Rails.logger.debug("** Copy Subjects to #{new_school.name}")

      subjs = Subject.where(school_id: model_school)

      subjs.each do |subj|
        match_item = Hash.new
        s = Subject.new
        s.name = subj.name
        match_item[:new_subject] = subj.name
        s.discipline_id = subj.discipline_id
        match_item[:new_discipline] = subj.discipline.name
        s.school_id = new_school.id
        s.subject_manager_id = subj.subject_manager_id
        fail("ERROR: error saving subject #{s.name} for #{new_school.name}") if !s.save
        match_item[:new_id] = s.id

        match_item[:old_id] = ''
        match_item[:old_discipline] = ''
        match_item[:old_subject] = ''
        match_item[:subject_outcomes] = copy_subject_los(subj.id, s.id)
        match_item[:error_str] = ''
        matches << match_item
      end

      Rails.logger.debug("** Done copying subjects to #{new_school.name}")

      return matches
    end


    # new UI school rollover process - copy learning outcomes from Model school
    # must rescue exceptions when calling this.
    # NOTE: this is untested for rollover (only tested for new school create)
    def copy_subject_los(old_subject_id, new_subject_id)
      matches = Array.new

      Rails.logger.debug("** Copy Subject #{old_subject_id} LOs to #{new_subject_id}")

      subjos = SubjectOutcome.where(subject_id: old_subject_id)

      subjos.each do |so|
        match_item = Hash.new
        s = SubjectOutcome.new
        s.name = so.name
        match_item[:new_lo_name] = so.name
        s.position = so.position
        match_item[:new_lo_position] = so.position
        s.marking_period = so.marking_period
        match_item[:new_lo_mp] = so.marking_period
        s.essential = so.essential
        match_item[:new_lo_essential] = so.essential
        s.subject_id = new_subject_id
        match_item[:new_subject_id] = new_subject_id
        fail("ERROR: error saving Learning Outcome #{s.name} for subject id #{new_subject_id}") if !s.save
        match_item[:old_lo_name] = ''
        match_item[:old_position] = ''
        match_item[:old_lo_mp] = ''
        match_item[:old_lo_essential] = ''
        match_item[:old_subject_id] = ''
        match_item[:error_str] = ''
        matches << match_item
      end

      Rails.logger.debug("** Done copying Learning Outcomes to subject ID #{new_subject_id}")

      return matches
    end




    def for_subgroup_proficiencies
      params[:races]      ||= RACES + ["", nil]
      params[:special_ed] ||= []
      # Set up special ed variable. Lengthy because no good way to go from "true" to true, "false" to false
      @special_ed = []
      @special_ed << false         if params[:special_ed].include? "false"
      @special_ed << true          if params[:special_ed].include? "true"
      @special_ed =  [false, true] if @special_ed.empty?

      @school   = School.find params[:id]
      @students = Student.alphabetical.where(school_id: params[:id]).in_race(params[:races]).special_ed_status(@special_ed)
      @high_performances    = SectionOutcomeRating.includes(:student).where(rating: "H", users: {school_id: params[:id], race: params[:races], special_ed: @special_ed})
      @proficients          = SectionOutcomeRating.includes(:student).where(rating: "P", users: {school_id: params[:id], race: params[:races], special_ed: @special_ed})
      @not_yet_proficients  = SectionOutcomeRating.includes(:student).where(rating: "N", users: {school_id: params[:id], race: params[:races], special_ed: @special_ed})
      params[:races].delete("")
      params[:races].delete(nil)
    end

    def remove_params
      if params[:school] and cannot?(:update_columns, @school)
        (School.column_names - ["id"]).map{ |a| a.to_sym }.each do |symbol|
          params[:school].delete symbol
        end
      end
    end
end
