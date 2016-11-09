# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class Teacher < User
  default_scope where(teacher: true, active: true)
  # default_scope order: 'LOWER(users.last_name), LOWER(users.first_name) ASC'

  # Access Control
  # using_access_control

  # Relationships
  belongs_to                    :school
  # TODO Break subject manager out into a many-to-many xref table.
  has_many                      :managed_subjects,
                                :as => :subject_manager,
                                :class_name => "Subject"
  has_many                      :teaching_assignments
  has_many                      :sections,
                                :through => :teaching_assignments

  # Validations
  validates_presence_of         :school_id

  # removed this so the correct array of roles in the user model is used
  # # Other Definitions
  # def role_symbols
  #   :teacher
  # end

  def section_outcomes
    SectionOutcome.where(section_id: sections.map{ |a| [a.id] })
  end
  def active_section_outcomes
    SectionOutcome.where(section_id: sections.map{ |a| [a.id] }, active: true)
  end
  def rated_section_outcomes_count
    SectionOutcomeRating.where(section_outcome_id: active_section_outcomes.pluck(:id), rating: ['H', 'P', 'N']).select("DISTINCT section_outcome_ratings.section_outcome_id").count
  end
  def active_evidence_section_outcomes
    EvidenceSectionOutcome.where(section_outcome_id: active_section_outcomes.pluck(:id))
  end
  def rated_evidence_section_outcomes_count
    EvidenceSectionOutcomeRating.where(evidence_section_outcome_id: active_evidence_section_outcomes.pluck(:id), rating: ['B', 'G', 'Y', 'R']).select("DISTINCT evidence_section_outcome_ratings.evidence_section_outcome_id").count
  end

end
