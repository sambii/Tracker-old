# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class Evidence < ActiveRecord::Base
  # Access Control
  # using_access_control

  # Relationships
  has_many                      :evidence_section_outcomes,
                                dependent: :destroy
  accepts_nested_attributes_for :evidence_section_outcomes,
                                reject_if: lambda { |a| a[:section_outcome_id].to_i < 1 or (a[:section_outcome_id] && a[:section_outcome_id][0] == 'x')},
                                allow_destroy: true # Note: this deletes ratings
  has_many                      :section_outcomes,
                                through: :evidence_section_outcomes
  has_many                      :evidence_section_outcome_ratings,
                                through: :evidence_section_outcomes
  belongs_to                    :section
  belongs_to                    :evidence_type
  has_many                      :evidence_attachments,
                                dependent: :destroy
  # review reject_if code - it prevented error detection of title
  accepts_nested_attributes_for :evidence_attachments,
                                reject_if: lambda { |a| a[:attachment].blank? },
                                allow_destroy: true
  has_many                      :evidence_hyperlinks,
                                dependent: :destroy
  accepts_nested_attributes_for :evidence_hyperlinks,
                                reject_if: lambda { |a| a[:hyperlink].blank? },
                                allow_destroy: true
  # Validations
  validates_presence_of         :name,
                                :assignment_date,
                                :section_id
  validates_numericality_of     :evidence_type_id, greater_than: 0

  # scopes
  scope :active_evidences, conditions: {active: true}

  # Other Definitions
  def clone_into_section section_id
    # Create a shallow clone and change the section id.
    # evidence. = self.clone caused an infinite loop with evidence_section_outcomes; not sure why.
    evidence = Evidence.new(
      name: name,
      assignment_date: assignment_date,
      description: description,
      evidence_type_id: evidence_type_id,
      section_id: section_id,
      reassessment: reassessment
    )

    # Verify the existence of and/or create the section outcome(s)
    evidence_section_outcomes.each do |e|
      section_outcome = SectionOutcome.find_or_initialize_by_section_id_and_subject_outcome_id(section_id, e.subject_outcome.id)
      section_outcome.marking_period ||= e.section_outcome.marking_period
      section_outcome.save

      # Create an evidence_section_outcome for the new section outcome.
      evidence.evidence_section_outcomes.build(section_outcome_id: section_outcome.id)
    end
    evidence_attachments.each do |e|
      evidence.evidence_attachments.build(name: e.name, attachment: e.attachment)
    end
    evidence_hyperlinks.each do |e|
      evidence.evidence_hyperlinks.build(title: e.title, hyperlink: e.hyperlink)
    end
    evidence.save
  end



  def evidence_type_name
    evidence_type.name
  end

  def hash_of_evidence_ratings
    return_value      = Hash.new { |h,k| h[k] = Hash.new({rating: "", comment: "", rating: false}) }
    evidence_ratings  = evidence_section_outcome_ratings
    evidence_ratings.each do |e|
      return_value[e.student_id][e.evidence_section_outcome_id] = {rating: e[:rating], comment: e[:comment], id: e.id}
    end
    return_value
  end

  def shortened_name
    n = name
    if n.length > 27
      n = n[0..26] + "..."
    end
    return n
  end
end
