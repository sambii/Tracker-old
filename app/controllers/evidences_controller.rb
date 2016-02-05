# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class EvidencesController < ApplicationController
  load_and_authorize_resource except: :rate

  # RESTful Methods

  # looks like part of rating
  # def show
  #   #
  #   # todo - remove @ratings instance variable from here - confirm not used in any evidences show calls
  #   @ratings = @evidence.hash_of_evidence_ratings
  #   respond_to do |format|
  #     format.json
  #   end
  # end


  # todo - Should this be here?  Is it used?

  # New UI
  # Bulk Rate Evidence
  # show a single Evidence Section Outcome in a Tracker Page like view for Bulk Evidence Ratings
  def show
    # set @section to only include the section outcomes for this evidence
    eso_sos = EvidenceSectionOutcome.where(evidence_id: @evidence.id).pluck(:section_outcome_id)
    Rails.logger.debug("*** eso_sos = #{eso_sos.inspect.to_s}")
    @section_outcomes = SectionOutcome.where(id: eso_sos)
    # @section = Section.includes(
    #   section_outcomes: {evidence_section_outcomes: :evidence}
    # )
    # if eso_sos.length > 1
    #   @section = @section.where('section_outcomes.id in (:so_id) and evidences.id = :evid_id', {
    #     so_id: eso_sos,
    #     evid_id: @evidence.id
    #   })
    # elsif eso_sos.length == 1
    #   @section = @section.where('section_outcomes.id = :so_id and evidences.id = :evid_id', {
    #     so_id: eso_sos,
    #     evid_id: @evidence.id
    #   })
    # else
    #   Rails.logger.error("*** missing ESOs for this evidence!! ")
    #   flash[:alert] = "*** missing ESOs for this evidence!! "
    # end
    # @section = @section.find(@evidence.section_id)
    @section = Section.find(@evidence.section_id)
    # info for Tracker Page like view.
    @marking_periods = Range::new(1,@evidence.section.school_year.school.marking_periods) #for when we want to set value in the school
    @students = @section.active_students(subsection: params[:subsection], by_first_last: @section.school.has_flag?(School::USER_BY_FIRST_LAST))
    @student_ids              = @students.collect(&:id)
    @section_outcome_ratings  = @section.hash_of_section_outcome_ratings
    @evidence_ratings         = @section.hash_of_evidence_ratings(evidence_id: @evidence.id)
    respond_to do |format|
      format.html { render layout: 'tracker_layout'}
      # format.json
    end
  end

  # New UI show the attachments for a single Evidence Section Outcome in a Tracker Page modal popup
  def show_attachments
    @section = Section.find(@evidence.section_id)
    respond_to do |format|
      format.js
    end
  end


  def index
    attributes = {}
    params.each_pair do |k,v|
      attributes[k] = v
    end
    @evidences = Evidence.where(attributes)

    respond_to do |format|
      format.json
    end
  end

  # New UI - used to handle the SectionController.new_evidence action
  # - add a new evidence (as well as eso, attachments and hyperlinks) to a section
  # process updates from:
  # - sections/#/new_evidence - Toolkit - Add Evidence.
  def create
    errors = 0
    error_str = ''

    if @evidence.errors.count > 0
      error_str += @evidence.errors.full_messages.to_s
      errors += 1
    end

    @section = Section.find(params[:section_id])

    # Get the other sections for this subject that the teacher/user can see
    # These are the sections that the newly created evidence can be copied to.
    @evidence_types   = EvidenceType.all
    # # get the other sections that the teacher has in the same subject
    # if current_user.teacher?
    #   teacher_sections = current_user.teacher.teaching_assignments.pluck(:section_id) - [@section.id]
    #   @sections = Section.where(subject_id: @section.subject_id, id: teacher_sections )
    # else
    #   @sections = []
    # end
    # Rails.logger.debug("*** matching sections for teacher: #{@sections.inspect.to_s}")
    # get the other sections that the teacher has in the same subject
    cur_sy_id = @section.subject.school.school_year_id
    if current_user.teacher? || current_user.school_administrator? || current_user.system_administrator?
      if current_user.teacher?
        other_sections = current_user.teacher.teaching_assignments.pluck(:section_id) - [@section.id]
      else
        other_sections = @section.subject.sections.pluck(:id) - [@section.id]
      end
      Rails.logger.debug("*** other_sections: #{other_sections.inspect.to_s}")
      @sections = Section.where(subject_id: @section.subject_id, id: other_sections, school_year_id: cur_sy_id )
      Rails.logger.debug("*** @sections: #{@sections.inspect.to_s}")
    else
      @sections = []
    end
    Rails.logger.debug("*** matching sections for teacher: #{@sections.inspect.to_s}")

    # get selected section outcomes
    selected_sos = []
    so_ids = params[:evidence][:evidence_section_outcomes_attributes]
    if so_ids.length > 0
      so_ids.each do |ik, iv|
        iv.each do |sok, sov|
          if sov[0] != 'x'
            selected_sos << sov.to_i
          end
        end
      end
    end
    Rails.logger.debug("*** selected_sos: #{selected_sos}")

    @esos = []
    @other_sos = SectionOutcome.where(section_id: @section.id, active: true).includes("subject_outcome")

    # Check to make sure assigned to at least one section outcome
    if selected_sos.length == 0
      error_str +=  ', Must be assigned to at least one Learning Outcome'
      @lo_errors = 'Must be assigned to at least one Learning Outcome.'
      errors += 1
    else
      @lo_errors = ''
    end

    if errors == 0
      if @evidence.save
        # This is probably not the 'Rails way' to do this, but clone_into_section method takes
        # an array of section ID's and creates the evidence, any absent learning outcomes, evidence
        # attachments, and evidence_section_outcomes in the additional sections.
        if params[:sections]
          Rails.logger.debug("*** copy evidence to other sections")
          params[:sections].each do |section_id|
            @evidence.clone_into_section section_id
            if @evidence.errors.count > 0
              error_str += ', '+@evidence.errors.full_messages.to_s
              errors += @evidence.errors.count
            end
          end
        end
      else
        error_str += ', '+@evidence.errors.full_messages.to_s
        errors += @evidence.errors.count
        Rails.logger.error("ERROR: EvidencesController.create error: #{error_str}")
      end
    end
    respond_to do |format|
      if errors > 0
        flash[:alert] = "ERRORS: Please fix errors below:"
        format.html
      else
        format.html { redirect_to section_path(@section) }
      end
    end

  end

  # New UI Edit Evidence functionality (combining ESO, Evidence, Attachments and Hyperlink edits for Tracker Page
  #    is found in
  # process updates from:
  # html - evidences/#/edit?eso_id=# - tracker page - edit evidence (attached to eso) icon.
  def edit
    # set @section to only include the section outcomes for this evidence
    @eso = EvidenceSectionOutcome.find(params[:eso_id])
    @eso_id = params[:eso_id]
    if @eso.errors.count == 0
      @evidence_types   = EvidenceType.all
      @section = @eso.section_outcome.section
      @sections = [] # no copy to other sections for edit (at this point)
      # get selected section outcomes
      selected_sos = []
      @evidence.section_outcomes.each do |so|
        selected_sos << so.id
      end
      @esos = EvidenceSectionOutcome.where(evidence_id: @evidence.id, section_outcome_id: selected_sos, section_outcomes: {active: true}).includes(section_outcome: :subject_outcome)
      other_sos = @other_sos = SectionOutcome.where(section_id: @section.id, active: true).includes("subject_outcome")
      other_sos_ids = other_sos.reject do |sos|
        selected_sos.include?(sos)
      end
      @other_sos = SectionOutcome.where(id: other_sos_ids).includes(:subject_outcome)
    else
      errors = true
    end
    respond_to do |format|
      # format.js
      if errors
        format.html { redirect_to root_path}
      else
        format.html
      end
    end
  end

  # New UI - used to handle the EvidenceController.edit action
  # - edit existing evidence (and possibly the attached ESOs, attachments, and hyperlinks)
  # process updates from:
  # html - evidences/#/edit?eso_id=# - tracker page - edit evidence (attached to eso) icon.
  # js - evidences/#.js?evidence[active]=false - tracker page - deactivate evidence (all ESOs as well).
  def update
    @errors = ''
    has_eso = false
    begin
      if params[:evidence][:evidence_section_outcomes_attributes]
        # edit evidence with eso updates as well
        has_eso = true
        @eso_id = params[:eso_id]
        @eso = EvidenceSectionOutcome.where(id: @eso_id).includes(section_outcome: :section).first
        if @eso.blank? || @eso.errors.count > 0
          @errors += (@eso.empty? || @eso.blank?) ? ", cannot find ESO: #{params[:eso_id]}" : ''
          @errors += @eso.errors.count > 0 ? ', '+@eso.errors.full_messages.join(", ") : ''
          raise 'cannot find ESO when updating ESO parameters passed'
        end
        # confirm we have at least one eso attached to evidence, else reject this update
        ok_to_update = false
        params[:evidence][:evidence_section_outcomes_attributes].each do |pk, pv|
          Rails.logger.debug("*** pk = #{pk}, pv = #{pv}")
          if pk.to_s[0] != 'x'
            ok_to_update = true if pv['_destroy'] == '0'
          else
            pv_so_id = pv['section_outcome_id']
            ok_to_update = true if !pv_so_id.blank? && pv_so_id[0] != 'x'
          end
        end
        if !ok_to_update
          err = "Must have at least one Learning Outcome attached to Evidence"
          @errors += ', '+err
          raise err
        end
      end

      @evidence.update_attributes(params[:evidence])
      if @evidence.errors.count > 0
        @errors += ', '+@evidence.errors.full_messages.join(", ")
        raise 'evidence update errors'
      end
    rescue => e
      flash[:alert] = 'ERRORS: '+@errors
      is_ok = false
    else
      is_ok = true
    end
    respond_to do |format|
      format.js
      if has_eso
        if !is_ok # && !@eso.blank?
          @evidence_types   = EvidenceType.all
          @section = @eso.section_outcome.section
          @sections = [] # no copy to other sections for edit (at this point)
          selected_sos = []
          @evidence.section_outcomes.each do |so|
            selected_sos << so.id
          end
          @esos = EvidenceSectionOutcome.where(evidence_id: @evidence.id, section_outcome_id: selected_sos, section_outcomes: {active: true}).includes(section_outcome: :subject_outcome)
          other_sos = @other_sos = SectionOutcome.where(section_id: @section.id, active: true).includes("subject_outcome")
          other_sos_ids = other_sos.reject do |sos|
            selected_sos.include?(sos)
          end
          @other_sos = SectionOutcome.where(id: other_sos_ids).includes(:subject_outcome)

          format.html  { render 'edit' }
        else  #if !@eso.blank?
          format.html { redirect_to section_path(params[:section_id]) }
        end
      else
        format.html { redirect_to(session[:return_to]) }
      end
    end
  end

  # Rate an entire class section for a given piece of evidence.
  # TODO examine if this can be eliminated and the functionality built into the show or edit action.
  def rate
    @evidence = Evidence.includes(section_outcomes: :subject_outcome).find(params[:id])
    authorize! :rate, @evidence
    @evidence_ratings = @evidence.hash_of_evidence_ratings
    section_outcomes = EvidenceSectionOutcome.section_outcomes_for_evidence(@evidence)
    @eso_section_outcomes = Hash.new
    section_outcomes.each do |eso|
      @eso_section_outcomes[eso.id] = {id: eso.section_outcome_id, name: eso.subject_outcome.name}
    end
    @enrollments = Enrollment.where(active: true, section_id: @evidence.section_id).includes(:student).alphabetical

    # todo - check usage - permanently remove this - duplicate of @evidence_ratings
    # @evidence_section_outcome_ratings = @evidence.hash_of_evidence_ratings

    respond_to do |format|
      format.js
      format.html
    end
  end

  def sort
    @evidences = @section_outcome.active_evidences
    @evidences.each do |evidence|
      evidence.position = 100 if evidence.position == nil
      evidence.position = params["evidences_"+@section_outcome.id.to_s].index(evidence.id.to_s)+1
      evidence.save
    end

    render nothing: true
  end

  # TODO determine if this can be eliminated, as it is simply a special case of the update action.
  def restore
    @evidences = Evidence.where()
    respond_to do |format|
      if @evidence.save
        format.html { redirect_to @evidence.section, :notice => @evidence.name + " was successfully restored." }
      end
    end
  end

end
