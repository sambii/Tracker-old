# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class EvidenceAttachmentsController < ApplicationController
  load_and_authorize_resource

  # RESTful Methods
  def index
    #
    # todo - remove this code - dead code - uses with_permissions_to from declarative_authorization gem
    #
    # This if block will scope the evidence attachments to a particular piece of evidence if the
    # evidence_id parameter is present.
    if params[:evidence_id]
      @evidence_attachments = EvidenceAttachment.where(:evidence_id => params[:evidence_id]).with_permissions_to(:index)
      @evidence = Evidence.where(:id => params[:evidence_id]).first
    else
      @evidence_attachments = EvidenceAttachment.with_permissions_to(:index)
    end
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    respond_to do |format|
      if @evidence_attachment.save
        format.html { redirect_to session[:return_to] }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # There is currently no way to edit or update an attachment. The file has to be deleted and
  # uploaded again. This seems fine.

  def destroy
    respond_to do |format|
      format.html { redirect_to session[:return_to] }
    end
  end
end
