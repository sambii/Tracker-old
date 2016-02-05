# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class EvidenceSectionOutcomeRatingsController < ApplicationController
  load_and_authorize_resource

  def show
    respond_to do |format|
      format.json # No practical use for a format.html block.
    end
  end

  # There is no need for an index action at the moment. Ratings tend to be accumulated by the
  # SectionOutcome, Evidence, EvidenceSectionOutcome and Student objects.

  def create
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
