# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SectionOutcomesController < ApplicationController
  load_and_authorize_resource except: :update

  # New UI
  # Bulk Rate Learning Outcome page
  # show a single Section Outcome in a Tracker Page like view for Bulk Section Outcome Ratings
  def show

    # set @section to only include the current section outcome
    @section = Section.scoped
    @section = @section.includes(
      section_outcomes: [ :section, :subject_outcome ]
    )
    @section = @section.where(section_outcomes: {id: @section_outcome.id})
    @section = @section.find(@section_outcome.section_id)

    # info for Tracker Page like view.
    @marking_periods = Range::new(1,@section.school.marking_periods) #for when we want to set value in the school
    @students = @section.active_students(subsection: params[:subsection], by_first_last: @section.school.has_flag?(School::USER_BY_FIRST_LAST))
    @student_ids              = @students.collect(&:id)
    @section_outcome_ratings  = @section.hash_of_section_outcome_ratings
    @evidence_ratings         = @section.hash_of_evidence_ratings

    respond_to do |format|
      format.html { render layout: 'tracker_layout'}
      # format.json
    end
  end

  # New UI
  # process updates from Add Section Outcome page (sections/#/new_section_outcome)
  # - POST "/section_outcomes" (as HTML)
  def create
    Rails.logger.debug("*** SectionOutcomeController.create started")
    begin
      raise NullParameterException unless params[:mp] && params[:section_outcome][:subject_outcome_id]

      @section_outcome = SectionOutcome.find_or_create({
                          section_id: params[:section_outcome][:section_id], subject_outcome_id: params[:section_outcome][:subject_outcome_id]
                         }, params[:section_outcome])

      # Math for marking period bitmask.
      marking_periods = params[:mp].sort{|a,b| a[1] <=> b[1]}
      @section_outcome.marking_period_bitmask!(marking_periods.map! { |a| a.to_i })

    rescue NullParameterException
      Rails.logger.error("Error: Marking period must be selected.")
      flash[:alert] = 'Error: Marking period must be selected.'
    rescue Exception
      Rails.logger.error("Error: the learning outcome was not added to this section!")
      flash[:alert] = 'Error: the learning outcome was not added to this section!'
    end

    Rails.logger.debug("*** @section_outcome.errors.count = #{@section_outcome.errors.count}")
    respond_to do |format|
      if @section_outcome.save
        format.js
        format.html { redirect_to new_section_outcome_section_path(@section_outcome.section_id) }
      else
        format.js { flash[:alert] = 'Error: The learning outcome was not added!' }
        format.html { redirect_to new_section_outcome_section_path(@section_outcome.section_id), notice: @section_outcome.errors.full_messages }
      end
    end
  end

  # New UI - used to deactivate Section Outcome on Tracker Page (as JS)
  # New UI - used to reactivate Section Outcomes on New Section Outcomes page (as HTML)
  def update
    @section_outcome = SectionOutcome.find(params[:id])
    # Math for marking period bitmask.
    if params[:mp]
      marking_periods = params[:mp].sort{|a,b| a[1] <=> b[1]}
      @section_outcome.marking_period_bitmask!(marking_periods.map! { |a| a.to_i })
    end

    Rails.logger.debug("*** @section_outcome.errors.count = #{@section_outcome.errors.count}")
    respond_to do |format|
      if @section_outcome.update_attributes(params[:section_outcome]) # testing - {active: true}) or false
        format.js # output handled by section_outcomes/update.js.erb
        format.html { redirect_to new_section_outcome_section_path(@section_outcome.section_id) }
      else
        format.js { render 'failure' }
        format.html { redirect_to new_section_outcome_section_path(@section_outcome.section_id), notice: @section_outcome.errors.full_messages }
      end
    end
  end

  def sort
    @section = Section.find(params[:section_id])
    @section_outcomes = @section.section_outcomes
    @section_outcomes.each do |section_outcome|
      section_outcome.position = params["section_outcomes"].index(section_outcome.id.to_s).to_i + 1
      section_outcome.save
    end
    render nothing: true
  end

  def evidences_left
    @section_outcome = SectionOutcome.includes(
      evidence_section_outcomes: [
            {evidence: :evidence_type},
            :section
          ]
    ).find(params[:id])
    @evidences = @section_outcome.evidence_section_outcomes

    respond_to do |format|

      format.html do
         render partial: 'evidences/left', layout: false, collection: @evidences,
               as: 'evidence', locals: {section_outcome: @section_outcome}
      end
    end

  end

  def evidences_right

    @section_outcome  = SectionOutcome.includes(
      evidence_section_outcomes: [
            {evidence: :evidence_type},
            :section
          ]
    ).find(params[:id])
    @evidences        = @section_outcome.evidence_section_outcomes
    @section          = @section_outcome.section
    @students         = @section.active_students(subsection: params[:subsection])
    @student_ids      = @students.collect(&:id)
    @evidence_ratings = @section.hash_of_evidence_ratings

    respond_to do |format|
      format.html do
        render partial: 'evidences/right', layout: false, collection: @evidences,
               as: 'evidence', locals: {section_outcome: @section_outcome}
      end
    end
  end


  # New UI
  # toggle one of the marking periods for a section outcome on the tracker page
  # just passing the current marking period and state
  # this action properly updates the marking periods bit mask
  # todo - process params[:mp_val] to make this a proper put, not a toggle
  def toggle_marking_period
    #
    @section_outcome = SectionOutcome.find(params[:id])
    this_mpi = params[:mp].nil? ? 0 : params[:mp].to_i
    Rails.logger.debug("*** this_mpi = #{this_mpi}")
    # this_mp_new_value = params[:mp_val] if params[:mp_val]
    mp_array = @section_outcome.marking_period_array
    Rails.logger.debug("*** @section_outcome.marking_period = #{@section_outcome.marking_period.inspect.to_s}")
    Rails.logger.debug("*** mp_array = #{mp_array.inspect.to_s}")
    if this_mpi > 0
      if mp_array.include? this_mpi
        mp_array.delete(this_mpi)
      else
        mp_array << this_mpi
      end
      @is_active = mp_array.include? this_mpi
      @this_mpi = this_mpi
      @section_outcome.update_attribute(:marking_period, @section_outcome.marking_period_bitmask!(mp_array))
      Rails.logger.debug("*** updated mp_array = #{mp_array.inspect.to_s}")
      Rails.logger.debug("*** @section_outcome.marking_period_bitmask! mp_array = #{@section_outcome.marking_period_bitmask!(mp_array).inspect.to_s}")
    end
    respond_to do |format|
      format.js
    end
  end

end
