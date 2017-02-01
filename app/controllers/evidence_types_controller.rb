# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class EvidenceTypesController < ApplicationController
  def index
    @evidence_types = EvidenceType.order(:name).all

    respond_to do |format|
      format.json # This response is used by forms in old UI?
      format.html # This response is used in Evidence Type Maintenance in New UI
    end
  end

  def new
    @evidence_type = EvidenceType.new
    authorize! :update, @evidence_type # only let maintainers do these things
    respond_to do |format|
      format.js{ render action: :add_edit }
    end
  end

  def create
    @evidence_type = EvidenceType.new(params[:evidence_type])
    authorize! :update, @evidence_type # only let maintainers do these things
    if @evidence_type.save
      flash[:notice] = I18n.translate('alerts.successfully') +  I18n.translate('action_titles.created')
    else
      flash[:alert] = I18n.translate('alerts.had_errors') + I18n.translate('action_titles.create')
    end
    Rails.logger.debug("+++ errors: #{@evidence_type.errors.inspect}")
    Rails.logger.debug("+++ error on name: #{@evidence_type.errors[:name]}")
    Rails.logger.debug("+++ error on base: #{@evidence_type.errors[:base]}")
    respond_to do |format|
      format.js { render action: :saved }
    end
  end

  def edit
    @evidence_type = EvidenceType.find(params[:id])
    authorize! :update, @evidence_type
    respond_to do |format|
      format.js
    end
  end

  def update
    @evidence_type = EvidenceType.find(params[:id])
    authorize! :update, @evidence_type
    if @evidence_type.update_attributes(params[:evidence_type])
      flash[:notice] = I18n.translate('alerts.successfully') +  I18n.translate('action_titles.updated')
    else
      flash[:alert] = I18n.translate('alerts.had_errors') + I18n.translate('action_titles.update')
    end
    respond_to do |format|
      format.js
    end
  end

end
