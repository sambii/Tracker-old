# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SectionOutcomeRatingsController < ApplicationController
  load_and_authorize_resource
  def show
    respond_to do |format|
      format.json
    end
  end

  def create
    # only update tracker page when not bulk (bulk update is refreshed)
    render_to = (params['bulk'] == 'true' ) ? {nothing:true} : 'update_tracker'
    Rails.logger.debug("*** params['bulk]: #{params['bulk']}, render_to: #{render_to}")
    respond_to do |format|
      if @section_outcome_rating.save
        format.js {render render_to}
      else
        Rails.logger.error("ERROR - create sor error: #{@section_outcome_rating.errors.full_messages.inspect.to_s}")
        format.js {render render_to, text: @section_outcome_rating.errors.full_messages.inspect.to_s}
      end
    end
  end

  def update
    render_to = (params['bulk'] == 'true' ) ? {nothing:true} : 'update_tracker'
    Rails.logger.debug("*** render_to: #{render_to}")
    respond_to do |format|
      if @section_outcome_rating.update_attributes params[:section_outcome_rating]
        format.js {render render_to}
      else
        Rails.logger.error("ERROR - update sor error: #{@section_outcome_rating.errors.full_messages.inspect.to_s}")
        format.js {render render_to, text: @section_outcome_rating.errors.full_messages.inspect.to_s}
      end
    end
  end
end
