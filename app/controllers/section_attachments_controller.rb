# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SectionAttachmentsController < ApplicationController
  load_and_authorize_resource

  # RESTful Methods
  def index
    #
    # todo - remove this code - dead code - uses with_permissions_to from declarative_authorization gem
    if params[:section_id]
      @section_attachments = SectionAttachment.where(:section_id => params[:section_id]).with_permissions_to(:index)
      @section = Section.where(:id => params[:section_id]).first
    else
      @section_attachments = SectionAttachment.with_permissions_to(:index)
    end
  end

  def show
  end

  def new
    #
    # todo - remove this code - dead code - uses with_permissions_to from declarative_authorization gem
    @section_attachment = SectionAttachment.new
    @section = Section.with_permissions_to(:update).find(params[:section_id])
  end

  def create
    @section_attachment = SectionAttachment.new(params[:section_attachment])

    respond_to do |format|
      if @section_attachment.save
        format.html {redirect_to @section_attachment.section}
      else
        p @section_attachment.errors
        format.html {render :action => "new"}
      end
    end
  end

  def destroy
    @section_attachment = SectionAttachment.find(params[:id])
    @section = @section_attachment.section
    @section_attachment.destroy

    respond_to do |format|
      format.html {redirect_to @section}
    end
  end
end
