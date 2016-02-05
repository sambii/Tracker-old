# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class Enrollment < ActiveRecord::Base
  # Access Control
  # using_access_control
  scope :alphabetical, joins(:student).where(active: true).order("users.last_name", "users.first_name")
  scope :current, { joins: { section: { subject: :school } }, conditions: ["sections.school_year_id = schools.school_year_id"] }
  scope :old,     { joins: { section: { subject: :school } }, conditions: ["sections.school_year_id != schools.school_year_id"] }
  scope :active_enrollment, where(active: true)

  # Relationships
  belongs_to                    :student
  accepts_nested_attributes_for :student
  belongs_to                    :section

  # Validations
  validates_presence_of         :student_grade_level
  validates_uniqueness_of       :student_id, :scope => :section_id, :message => "This student is already enrolled in that class section!"
  validates_numericality_of     :subsection, :if => lambda { |enrollment| enrollment.subsection.present? }

  #callbacks
  before_save                   :fix_subsection

  def fix_subsection
    self.subsection = 0 if self.subsection.blank?
  end

  #todo have this work on enrollment section
  def hash_of_section_outcome_rating_counts(options = {})
    options[:marking_periods] ||= (1..10).to_a
    hash = Hash.new { |h,k| h[k] = { H: 0, P: 0, N: 0, U: 0 } }
    section_outcome_ratings = SectionOutcomeRating.joins(:section_outcome).where(student_id: student_id, section_outcomes: { active: true })
    section_outcome_ratings.each do |section_outcome_rating|
      if (section_outcome_rating.section_outcome.marking_period_array & options[:marking_periods]).length > 0
        unless section_outcome_rating.rating.blank?
          rating = section_outcome_rating.rating[0]
          hash[section_outcome_rating.section_outcome.section_id][rating.to_sym] ||= 0
          hash[section_outcome_rating.section_outcome.section_id][rating.to_sym] += 1
        end
      end
    end
    return hash
  end

  # New UI for Student Dashboard Summary Evidence Stats
  #todo have this work on enrollment section
  def count_section_evidence_ratings section_id, start_date=nil
    hash = {'B' => 0, 'G' => 0, 'Y' => 0, 'R' => 0, 'M' => 0, 'U' => 0}
    query = EvidenceSectionOutcomeRating.joins(:evidence).where(
      student_id: student_id,
      evidences: { section_id: section_id, active: true }
    )
    if start_date.present?
      as_date = start_date.to_date
      Rails.logger.debug("*** as_date: #{as_date}")
      query = query.where(updated_at: as_date..1.day.from_now.to_date)
    end
    query.each do |esor|
      Rails.logger.debug("*** esor: #{esor.inspect.to_s}")
      hash["#{esor.rating[0]}"] += 1 if !esor.rating.nil? && esor.rating.length > 0
    end
    Rails.logger.debug("*** hash: #{hash.inspect.to_s}")
    hash
  end


end
