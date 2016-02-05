# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class EvidenceTypesController < ApplicationController
  # This action is used by forms to pull the evidence types from the database. Hence the .json response.
  def index
    @evidence_types = EvidenceType.order(:name).all

    respond_to do |format|
      format.json
    end
  end

  # TODO Add new and create actions so that administrators can eventually handle this themselves.
  # TODO Possibly add an edit option to allow administrators to 'retire' a type of evidence.
end
