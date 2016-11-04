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
        format.js {render render_to}
      else
        p @evidence_section_outcome_rating.errors
        format.js {render render_to, text: @evidence_section_outcome_rating.errors.full_messages.inspect.to_s}
      end
    end
  end

  def update
    # coding to manually authorize, to avoid cancan error 500
    if params[:id]
      sorid = params[:id]
    elsif params[:evidence_section_outcome_rating]
      sorid = params[:evidence_section_outcome_rating]
    elsif params[:section_outcome_rating][:id]
      sorid = params[:section_outcome_rating][:id]
    else
      sorid = 0 # will fail
    end
    @evidence_section_outcome_rating = EvidenceSectionOutcomeRating.find(sorid)
    authorize! :update, @evidence_section_outcome_rating # only let maintainers do these things

    Rails.logger.debug("*** esor params: #{params[:evidence_section_outcome_rating]}")
    render_to = (params['bulk'] == 'true' ) ? {nothing:true} : 'update_tracker'
    respond_to do |format|
      if @evidence_section_outcome_rating.update_attributes params[:evidence_section_outcome_rating]
        Rails.logger.debug("*** Updated esor: #{@evidence_section_outcome_rating.inspect.to_s}")
        format.js {render render_to}
      else
        Rails.logger.error("*** ERROR updating esor: #{@evidence_section_outcome_rating.errors.full_messages.inspect.to_s}")
        p @evidence_section_outcome_rating.errors
        format.js {render render_to, text: @evidence_section_outcome_rating.errors.full_messages.inspect.to_s}
      end
    end
  end
end
