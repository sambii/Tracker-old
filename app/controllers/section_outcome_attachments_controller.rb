# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SectionOutcomeAttachmentsController < ApplicationController
  load_and_authorize_resource

  # RESTful Methods
  def index
    #
    # todo - remove this code - dead code - uses with_permissions_to from declarative_authorization gem
    if params[:section_outcome_id]
      @section_outcome_attachments = SectionOutcomeAttachment.where(:section_outcome_id => params[:section_outcome_id]).with_permissions_to(:index)
      @section_outcome = SectionOutcome.where(:id => params[:section_outcome_id]).first
    else
      @section_outcome_attachments = SectionOutcomeAttachment.with_permissions_to(:index)
    end
  end

  def show
  end

  def new
    #
    # todo - remove this code - dead code - uses with_permissions_to from declarative_authorization gem
    @section_outcome_attachment = SectionOutcomeAttachment.new

    @section_outcome = SectionOutcome.with_permissions_to(:manage).find(params[:section_outcome_id])
    @section = @section_outcome.section
    @sections = Section.with_permissions_to(:update)
  end

  def create
    @section_outcome_attachment = SectionOutcomeAttachment.new(params[:section_outcome_attachment])

    respond_to do |format|
      if @section_outcome_attachment.save
        format.html {redirect_to @section_outcome_attachment.section_outcome.section}
      else
        p @section_outcome_attachment.errors
        format.html {render :action => "new"}
      end
    end
  end

  def destroy
    @section_outcome_attachment = SectionOutcomeAttachment.find(params[:id])
    @section = @section_outcome_attachment.section_outcome.section
    @section_outcome_attachment.destroy

    respond_to do |format|
      format.html {redirect_to @section}
    end
  end
end
