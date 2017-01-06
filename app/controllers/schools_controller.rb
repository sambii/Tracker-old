# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SchoolsController < ApplicationController

  load_and_authorize_resource
  before_filter :remove_params, only: [:update]

  # RESTful Methods
  def show
    @school = School.includes(:school_year).find(params[:id])
    template = "schools/show"
    template = "schools/reports/#{params[:report]}" if params[:report]

    if template == "schools/show"
      # to do - review this commented out code for possible extra security precautions.
      # @school = School.includes(students: {enrollments: {section: [:subject, teaching_assignments: :teacher]}}).find(params[:id])
      # @school = School.includes(:school_year).find(params[:id])
      set_school_context
    else
      for_subgroup_proficiencies
    end

    respond_to do |format|
      # todo - review this flow, maybe show should not be used here.
      if template == "schools/show"
        # to do - authorize only user types given :summary action on School (action used in many places - needs full testing)
        # authorize! :summary, School
        format.html
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
    # Ensure School rollover always active for Model School for System Administrators
    @model_school = get_model_school('MOD')
    # List schools user has authorization for
    @schools = School.accessible_by(current_ability).order('name')
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
          @school = School.find(params[:id])
        else
          fail 'Missing school ID'
        end
        model_schools = School.where(acronym: 'MOD')

        Rails.logger.debug("*** School Year: #{@school.school_year.ends_at.year}, #{@school.inspect}, #{@school.school_year.inspect}")
        Rails.logger.debug("*** Model School Year: #{model_schools.first.school_year.ends_at.year}, #{model_schools.first.inspect}, #{model_schools.first.school_year.inspect}")

        # ensure school year is less than model school's year.
        if model_schools.count == 1
          if model_schools.first.school_year
            if model_schools.first.school_year.ends_at.year > @school.school_year.ends_at.year || @school.id == model_schools.first.id
              # ok to roll over
            else
              fail "ERROR: Cannot roll over year till Model School is rolled over."
            end
          else
            fail "ERROR: Model School does not have a school year."
          end
        end

        Rails.logger.debug("*** Update School Year: #{@school.school_year.ends_at.year}, #{@school.inspect}, #{@school.school_year.inspect}")
        Rails.logger.debug("*** Update Model School Year: #{model_schools.first.school_year.ends_at.year}, #{model_schools.first.inspect}, #{model_schools.first.school_year.inspect}")

        # increment student grade levels for all students in school, deactivate students > max grade (3 - egypt, 12 - others)
        rollover_student_grade_levels(@school)

        notice_msg = ''
        # Copy subjects and learning outcomes from model school if it exists.
        if model_schools.count == 1
          if @school.acronym == 'MOD'
            # make sure the model_lo_id field is preset before rolling over
            if SubjectOutcome.where('model_lo_id IS NOT NULL').count == 0
              # ensure model_lo_id fields in subject outcomes for all schools are preset to model school subject outcomes.
              School.all.each do |s|
                if s.id != @school.id
                  # only do this for schools not the model school
                  s.preset_model_lo_id
                end
              end
            end
          else
            copy_subjects(model_schools.first, @school)
          end
          notice_msg = "School year was successfully rolled over."
        else
          notice_msg = 'School year was successfully rolled over (without Model School LOs).'
        end
        rollover_school_year(@school)
        format.html { redirect_to( schools_path, notice: notice_msg) }


      rescue Exception => e
        Rails.logger.error("ERROR in School.new_year_rollover: Exception #{e.message}")
        format.html { redirect_to( schools_path, alert: "Error on School Year rollover: #{e.message}") }
      end
    end
  end

  # New UI - School Dashboard
  def dashboard

    current_sect_ids = []

    if (@current_user.system_administrator? || @current_user.researcher?)
      set_school_context
      @school = @current_school
    # else
    #   @school = get_current_school
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
      @by_lo_count = @subject_ratings.sort_by{|k,v| (v[:ratio])}.reverse

      @recent10 = User.where('(teacher=? OR counselor=? OR school_administrator=?) AND current_sign_in_at IS NOT NULL AND school_id=?', true, true, true, @school.id).order(:last_name, :first_name).order('current_sign_in_at DESC').limit(10)
    end

    respond_to do |format|
      format.html
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
      next_year_records = SchoolYear.where(school_id: school.id, name: year_name)
      if next_year_records.count > 0
        school_year = next_year_records.first
      else
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


    # new UI school create or rollover process - copy subjects from Model school
    def copy_subjects(model_school, new_school)
      matches = Array.new

      Rails.logger.debug("** Copy Subjects to #{new_school.name}")

      subjs = Subject.where(school_id: model_school)

      subjs.each do |subj|
        match_item = Hash.new
        match_item[:discipline] = subj.discipline.name
        match_item[:subject] = subj.name
        ns_subjs = Subject.where(name: subj.name, school_id: new_school.id)
        if ns_subjs.count == 0
          s = Subject.new
          s.name = subj.name
          s.discipline_id = subj.discipline_id
          s.school_id = new_school.id
          s.subject_manager_id = subj.subject_manager_id
          fail("ERROR: error saving subject #{s.name} for #{new_school.name}") if !s.save
          match_item[:subj_id] = s.id
          match_item[:error_str] = ''
        elsif ns_subjs.count == 1
          s = ns_subjs.first
          match_item[:error_str] = ''
        else
          err = "ERROR: System Error multiple subjects with name: #{subj.name} for school: #{new_school.name}"
          fail(err)
          match_item[:error_str] = err
        end

        if match_item[:error_str].blank?
          match_item[:subject_outcomes] = copy_model_los(subj.id, s.id)
        end
        matches << match_item
      end

      Rails.logger.debug("** Done copying subjects to #{new_school.name}")

      return matches
    end


    # new UI school create or rollover process - copy learning outcomes from Model school
    def copy_model_los(model_subject_id, sch_subject_id)

      # Note: should loop through existing school learning outcomes, to update from their matching model records

      # Then shouls loop through model school learning outcomes, to ensure all new ones are added

      # Reporting
      matches = Array.new

      Rails.logger.debug("** Copy Subject #{model_subject_id} LOs to #{sch_subject_id}")

      Rails.logger.debug("** Copy Subject update from model_lo_id")

      # update subject outcomes from model school using model_lo_id if it exists
      sch_subjos = SubjectOutcome.where(subject_id: sch_subject_id, active: true)
      sch_subjos.each do |so|
        Rails.logger.debug("*** so: #{so.inspect}")
        if so.model_lo_id.present?
          Rails.logger.debug("*** id Present #{so.model_lo_id}")
          begin
            mod_so = SubjectOutcome.find(so.model_lo_id)
          rescue
            mod_so = nil
          end
          match_item = Hash.new
          match_item[:error_str] = ''
          if mod_so.present?
            Rails.logger.debug("*** model rec Present")
            so.lo_code = mod_so.lo_code
            so.description = mod_so.description
            so.marking_period = mod_so.marking_period
            so.active = mod_so.active
            if !so.save
              match_item[:error_str] = "ERROR: error saving Learning Outcome #{so.name} for subject id #{sch_subject_id}, errors: #{so.errors.full_messages}"
              fail(match_item[:error_str]) if match_item[:error_str]
              Rails.logger.error(match_item[:error_str])
            end
            match_item[:lo_name] = so.name
            match_item[:lo_position] = so.position
            match_item[:lo_mp] = so.marking_period
            match_item[:lo_essential] = so.essential
            match_item[:subject_id] = sch_subject_id
            match_item[:model_lo_id] = so.id
            matches << match_item
          else
            Rails.logger.debug("*** error")
            match_item[:error_str] = "ERROR: Missing Model LO pointed to by model_lo_id: #{so.model_lo_id} in record: #{so.id}"
            # fail(match_item[:error_str])
            Rails.logger.error(match_item[:error_str])
            matches << match_item
          end
        end
      end

      Rails.logger.debug("** Update Rest")
      # Update rest of subject outcomes (without model_lo_id)
      mod_subjos = SubjectOutcome.where(subject_id: model_subject_id, )
      mod_subjos.each do |mod_so|
        Rails.logger.debug("*** mod_so: #{mod_so.inspect}")
        so = nil
        match_item = Hash.new
        match_item[:error_str] = ''
        ns_subjos = SubjectOutcome.where(subject_id: sch_subject_id, description: mod_so.description)
        if ns_subjos.count == 0
          Rails.logger.debug("*** Does not exist - add it")
          # does not exist, add it
          so = SubjectOutcome.new
        else
          Rails.logger.debug("*** Exists")
          if ns_subjos.first.model_lo_id.blank?
            Rails.logger.debug("*** Exists and blank ID")
            so = ns_subjos.first
          else
            Rails.logger.debug("*** ID present - ignore it")
            # ignore this record - should have already been updated above from model_lo_id update
            so = nil
          end
        end
        if so.present?
          Rails.logger.debug("*** ID present - save it")
          match_item[:lo_name] = mod_so.name
          match_item[:lo_position] = mod_so.position
          match_item[:lo_mp] = mod_so.marking_period
          match_item[:lo_essential] = mod_so.essential
          match_item[:subject_id] = sch_subject_id
          match_item[:model_lo_id] = mod_so.id
          so.lo_code = mod_so.lo_code
          so.description = mod_so.description
          so.marking_period = mod_so.marking_period
          so.active = mod_so.active
          so.subject_id = sch_subject_id
          so.model_lo_id = mod_so.id
          if !so.save
            Rails.logger.error("ERROR: #{so.inspect}")
            match_item[:error_str] = "ERROR: error saving Learning Outcome #{so.name} for subject id #{sch_subject_id}, errors: #{so.errors.full_messages}"
            fail(match_item[:error_str])
          end
          matches << match_item
        end
      end

      Rails.logger.debug("** Done copying Learning Outcomes to subject ID #{sch_subject_id}")

      return matches
    end

    def rollover_student_grade_levels(school)
      # should be run after school year has been updated
      max_grade = 12
      max_grade = 3 if school.has_flag?(School::USER_BY_FIRST_LAST)
      Rails.logger.debug("+#}% max_grade: #{max_grade}")
      # increment student grade levels for all students in school, deactivate students > max grade (3 - egypt, 12 - others)
      Student.where(school_id: school.id).each do |st|
        if st.grade_level == max_grade
          new_grade_level = school.school_year.starts_at.year
        else
          new_grade_level = st.grade_level + 1
        end
        st.grade_level = new_grade_level
        fail("ERROR: error incrementing grade level for student: #{st.id} - #{st.name} for #{@school.name}") if !st.save
        Enrollment.where(student_id: st.id).each do |e|
          e.student_grade_level = new_grade_level
          fail("ERROR: error incrementing grade level for student enrollment: #{st.id} - #{st.name} - #{e.id} for #{@school.name}") if !e.save
        end
      end
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
