# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class EvidenceSectionOutcomeRatingsController < ApplicationController
  # load_and_authorize_resource

  def show

    # where is this used?
    @evidence_section_outcome_rating = EvidenceSectionOutcomeRating.find(params[:id])
    authorize! :show, @evidence_section_outcome_rating

    respond_to do |format|
      format.json # No practical use for a format.html block.
    end
  end

  # There is no need for an index action at the moment. Ratings tend to be accumulated by the
  # SectionOutcome, Evidence, EvidenceSectionOutcome and Student objects.

  def create
    @evidence_section_outcome_rating = EvidenceSectionOutcomeRating.new(params[:evidence_section_outcome_rating])
    authorize! :create, @evidence_section_outcome_rating # only let maintainers do these things

    # only update tracker page when not bulk (bulk update is refreshed)
    render_to = (params['bulk'] == 'true' ) ? {nothing:true} : 'update_tracker'

    respond_to do |format|
      if @evidence_section_outcome_rating.save
        @section_outcome_id = @evidence_section_outcome_rating.evidence_section_outcome.section_outcome_id
        format.js {render render_to}
      else
        @section_outcome_id = 0
        format.js {render render_to, alert: @evidence_section_outcome_rating.errors.full_messages.inspect.to_s}
      end
    end
  end

  def update
    # coding to manually authorize, to avoid cancan error 500
    if params[:id]
      esorid = params[:id]
    # not sure if these are needed. check where this is called!
    elsif params[:evidence_section_outcome_rating_id]
      esorid = params[:evidence_section_outcome_rating_id]
    elsif params[:evidence_section_outcome_rating][:id]
      esorid = params[:evidence_section_outcome_rating][:id]
    else
      esorid = 0 # will fail
    end
    begin
      @evidence_section_outcome_rating = EvidenceSectionOutcomeRating.find(esorid)
      @section_outcome_id = @evidence_section_outcome_rating.evidence_section_outcome.section_outcome_id
    rescue
      @evidence_section_outcome_rating = EvidenceSectionOutcomeRating.new(params[:evidence_section_outcome_rating])
      @evidence_section_outcome_rating.errors.add(:base, "ERROR - Please reload page, Missing esor record: #{esorid.inspect}")
      @section_outcome_id = 0
    end


    authorize! :update, @evidence_section_outcome_rating # only let maintainers do these things

    render_to = (params['bulk'] == 'true' ) ? {nothing:true} : 'update_tracker'
    respond_to do |format|
      if  (@evidence_section_outcome_rating.errors.count == 0) && (@evidence_section_outcome_rating.update_attributes params[:evidence_section_outcome_rating])
        format.js {render render_to}
      else
        Rails.logger.error("ERROR - updating esor: #{@evidence_section_outcome_rating.errors.full_messages.inspect.to_s}")
        format.js {render render_to, alert: @evidence_section_outcome_rating.errors.full_messages.inspect.to_s}
      end
    end
  end
end
