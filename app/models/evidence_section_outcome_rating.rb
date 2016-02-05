# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class EvidenceSectionOutcomeRating < ActiveRecord::Base
  attr_accessible             :comment, :evidence_section_outcome_id, :flagged, :rating, :student_id
  attr_readonly               :evidence_section_outcome_id, :student_id
  before_save                 :populate_rating, :upcase_rating
  before_validation           :uniquify, on: :create

  belongs_to                  :evidence_section_outcome
  has_one                     :evidence, through: :evidence_section_outcome
  has_one                     :section_outcome, through: :evidence_section_outcome
  has_one                     :section, through: :section_outcome
  belongs_to                  :student

  validates_uniqueness_of     :student_id, scope: [:evidence_section_outcome_id], on: :create
  validate                    :validate_flagged

  def reassessment
    evidence.reassessment
  end

  protected
    def populate_rating
      self.rating = "" unless rating?
    end

    def uniquify
      EvidenceSectionOutcomeRating.where(evidence_section_outcome_id: evidence_section_outcome_id, student_id: student_id).each do |a|
        a.destroy unless a.id == id
      end
    end

    def upcase_rating
      self.rating.upcase!
    end

    def validate_flagged
      if self.flagged and !evidence.reassessment
        errors.add(flagged: "Can only flag a reassessment!")
      end
    end
end
