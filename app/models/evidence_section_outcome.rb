# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class EvidenceSectionOutcome < ActiveRecord::Base
  attr_accessible :evidence_id, :position, :section_outcome_id, :evidence_section_outcome_ratings_attributes
  # default_scope   order: 'evidence_section_outcomes.position ASC'

  belongs_to                    :evidence
  has_many                      :evidence_attachments, through: :evidence
  belongs_to                    :section_outcome
  has_one                       :subject_outcome, through: :section_outcome
  has_one                       :section, through: :section_outcome
  has_many                      :evidence_section_outcome_ratings
  accepts_nested_attributes_for :evidence_section_outcome_ratings,
                                reject_if: lambda { |a| a[:rating].blank? }

  # Scopes
  def self.section_outcomes_for_evidence(evidence_id)
    includes(:section_outcome).where("evidence_section_outcomes.evidence_id = ?", evidence_id)
  end

  def assignment_date
    evidence.assignment_date
  end

  def description
    evidence.description
  end

  def evidence_attachments
    evidence.evidence_attachments
  end

  def evidence_hyperlinks
    evidence.evidence_hyperlinks
  end

  def evidence_type
    evidence.evidence_type
  end

  def name
    evidence.name
  end

  def section_outcome_name
    section_outcome.name
  end

  def reassessment
    evidence.reassessment
  end

  def rated?
    e = EvidenceSectionOutcomeRating.arel_table
    if EvidenceSectionOutcomeRating.where({evidence_section_outcome_id: id}, e[:rating].not_in(["", "", nil])).length > 0
      return true
    else
      return false
    end
  end

  def shortened_name
    evidence.shortened_name
  end
end
