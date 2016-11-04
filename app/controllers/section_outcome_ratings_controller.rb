# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SectionOutcomeRatingsController < ApplicationController
  # load_and_authorize_resource

  def show

    # where is this used?
    begin
      @section_outcome_rating = SectionOutcomeRating.find(params[:id])
    rescue
      @section_outcome_rating = SectionOutcomeRating.new
      @section_outcome_rating.errors.add(:base, "ERROR - Missing esor record with id: #{params[:id].inspect}")
    end
    authorize! :show, @section_outcome_rating

    respond_to do |format|
      format.json
    end
  end

  def create
    @section_outcome_rating = SectionOutcomeRating.new(params[:section_outcome_rating])
    authorize! :create, @section_outcome_rating # only let maintainers do these things

    # only update tracker page when not bulk (bulk update is refreshed)
    render_to = (params['bulk'] == 'true' ) ? {nothing:true} : 'update_tracker'
    respond_to do |format|
      if @section_outcome_rating.save
        format.js {render render_to}
      else
        Rails.logger.error("ERROR - create sor error: #{@section_outcome_rating.errors.full_messages.inspect.to_s}")
        format.js {render render_to, alert: @section_outcome_rating.errors.full_messages.inspect.to_s}
      end
    end
  end

  def update
    # coding to manually authorize, to avoid cancan error 500
    if params[:id]
      sorid = params[:id]
    # not sure if these are needed. check where this is called!
    elsif params[:section_outcome_rating_id]
      sorid = params[:section_outcome_rating_id]
    elsif params[:section_outcome_rating][:id]
      sorid = params[:section_outcome_rating][:id]
    else
      sorid = 0 # will fail
    end
    begin
      @section_outcome_rating = SectionOutcomeRating.find(sorid)
    rescue
      @section_outcome_rating = SectionOutcomeRating.new
      @section_outcome_rating.errors.add(:base, "ERROR - Please reload page, Missing sor record: #{sorid.inspect}")
    end

    authorize! :update, @section_outcome_rating # only let maintainers do these things

    render_to = (params['bulk'] == 'true' ) ? {nothing:true} : 'update_tracker'
    respond_to do |format|
      if (@section_outcome_rating.errors.count == 0) && (@section_outcome_rating.update_attributes params[:section_outcome_rating])
        format.js {render render_to}
      else
        Rails.logger.error("ERROR - update sor error: #{@section_outcome_rating.errors.full_messages.inspect.to_s}")
        format.js {render render_to, alert: @section_outcome_rating.errors.full_messages.inspect.to_s}
      end
    end
  end
end
