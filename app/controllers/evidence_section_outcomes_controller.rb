# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class EvidenceSectionOutcomesController < ApplicationController
  load_and_authorize_resource

  def show
    respond_to do |format|
      format.json
    end
  end


  # New UI Edit Evidence functionality (combining ESO, Evidence, Attachments and Hyperlink edits for Tracker Page
  def edit
    # set @section to only include the section outcomes for this evidence
    @evidence = @evidence_section_outcome.evidence
    @evidence_types   = EvidenceType.all
    @section = @evidence_section_outcome.section_outcome.section
    @sections = [] # no copy to other sections for edit (at this point)
    Rails.logger.debug("*** attachments")
    @evidence.evidence_attachments.each do |ea|
      Rails.logger.debug("*** attachment #{ea.name}")
    end
    Rails.logger.debug("*** hyperlinks")
    @evidence.evidence_hyperlinks.each do |eh|
      Rails.logger.debug("*** hyperlink #{eh.title}")
    end

    # get selected section outcomes
    selected_sos = []
    @evidence.section_outcomes.each do |so|
      selected_sos << so.id
    end
    Rails.logger.debug("*** selected_sos: #{selected_sos}")
    @sos = SectionOutcome.where(id: selected_sos, active: true).includes("subject_outcome")
    @other_sos = SectionOutcome.where("id not in (?) and section_id = ?", selected_sos, @section.id)
    respond_to do |format|
      format.js
      format.html
    end
  end



  def update
    respond_to do |format|
      if @evidence_section_outcome.update_attributes(params[:evidence_section_outcome])
        format.js
      else
        format.js { render js: "alert('Changes could not be saved!');" }
      end
    end
  end

  # Other Definitions
  def sort
    @section_outcome = SectionOutcome.find params[:section_outcome_id]
    @evidence_section_outcomes = @section_outcome.evidence_section_outcomes
    @evidence_section_outcomes.each do |evidence_section_outcome|
      evidence_section_outcome.position = params["evidence_section_outcomes"].index(evidence_section_outcome.id.to_s).to_i + 1
      evidence_section_outcome.save
    end

    render nothing: true
  end
end
