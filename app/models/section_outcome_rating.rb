# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SectionOutcomeRating < ActiveRecord::Base
  # Access Control
  # using_access_control

  # Relationships
  belongs_to                        :student
  belongs_to                        :section_outcome
  has_one                           :section,
                                    :through => :section_outcome
  has_one                           :subject_outcome,
                                    :through => :section_outcome

  # Validations
  validates_presence_of             :rating,
                                    :student_id,
                                    :section_outcome_id
  validates_uniqueness_of           :student_id, :scope => [:section_outcome_id]

  before_validation                 :uniquify
  # Scopes

  # class methods

  # New UI - Teacher Dashboard page Overall Student Performance & Proficiency Bars blocks
  # New UI - Class Dashboard page Overall Student Performance
  def self.hash_of_section_outcome_rating_by_section(options = {})
    cur_section_ids = options[:section_ids].present? ? options[:section_ids] : []
    options[:marking_periods] ||= (1..10).to_a
    hash = Hash.new { |h,k| h[k] = { H: 0, P: 0, N: 0, U: 0 } }
    # todo - find out why Active Record needs to keep on hitting School cache (performance issue)
    active_enr = Hash.new { |h, k| h[k] = { } }
    Enrollment.where(section_id: cur_section_ids).each do |e|
      active_enr[e.section_id][e.student_id] = e.active
    end
    sors = SectionOutcomeRating.includes(:student, section_outcome: {section: { subject: :school }}).where(section_outcomes: { active: true, section_id: cur_section_ids}, users: {active: true})
    sors.each do |sor|
      # todo - review this marking period logic
      if (sor.section_outcome.marking_period_array & options[:marking_periods]).length > 0
        # do not count nils
        if sor.rating.present? && active_enr[sor.section_outcome.section_id][sor.student_id]
          rating = sor.rating[0]
          hash[sor.section_outcome.section_id][rating.to_sym] ||= 0
          hash[sor.section_outcome.section_id][rating.to_sym] += 1
        end
      end
    end
    # Rails.logger.debug("*** by section hash = #{hash.inspect.to_s}")
    return hash
  end


  # New UI - Class Dashboard page Section Outcome Proficiency Bars
  def self.hash_of_section_outcome_rating_by_so(options = {})
    cur_section_ids = options[:section_ids].present? ? options[:section_ids] : []
    options[:marking_periods] ||= (1..10).to_a
    hash = Hash.new { |h,k| h[k] = { H: 0, P: 0, N: 0, U: 0 } }
    active_enr = Hash.new { |h, k| h[k] = { } }
    Enrollment.where(section_id: cur_section_ids).each do |e|
      active_enr[e.section_id][e.student_id] = e.active
    end
    sors = SectionOutcomeRating.includes(:student, :section_outcome).where(section_outcomes: { active: true, section_id: cur_section_ids}, users: {active: true})
    sors.each do |sor|
      # todo - review this marking period logic
      if (sor.section_outcome.marking_period_array & options[:marking_periods]).length > 0
        # do not count nils
        if sor.rating.present? && active_enr[sor.section_outcome.section_id][sor.student_id]
          rating = sor.rating[0]
          hash[sor.section_outcome_id][rating.to_sym] ||= 0
          hash[sor.section_outcome_id][rating.to_sym] += 1
        end
      end
    end
    Rails.logger.debug("*** by so hash = #{hash.inspect.to_s}")
    return hash
  end


  # New UI - Teacher Dashboard page Students NYP Counts block
  # New UI - Class Dashboard page Students NYP Counts
  def self.hash_of_students_rating_by_section(options = {})
    cur_section_ids = options[:section_ids].present? ? options[:section_ids] : []
    hash = Hash.new { |h,k| h[k] = { H: 0, P: 0, N: 0 } }
    active_enr = Hash.new { |h, k| h[k] = { } }
    Enrollment.where(section_id: cur_section_ids).each do |e|
      active_enr[e.section_id][e.student_id] = e.active
    end
    options[:marking_periods] ||= (1..10).to_a
    sors = SectionOutcomeRating.includes.includes(:section_outcome).where(section_outcomes: { active: true, section_id: cur_section_ids})
    sors.each do |sor|
      # todo - review this marking period logic
      if (sor.section_outcome.marking_period_array & options[:marking_periods]).length > 0
        if active_enr[sor.section_outcome.section_id][sor.student_id]
          # todo - why are missing ratings set to U here (see above methods)?
          rating = sor.rating.present? ? sor.rating[0] : 'U'
          hash[sor.student_id][rating.to_sym] ||= 0
          hash[sor.student_id][rating.to_sym] += 1
        end
      end
    end
    return hash
  end


  # Other Definitions
  def active
    section_outcome.active
  end

  def rating_long
    if (rating == "H" or rating == "H*")
      return "High Performance"
    end
    return "Proficient" if rating == "P" or rating == "P*"
    return "Not Yet Proficient" if rating == "N" or rating == "N*"
    return "Unrated" if rating == "U" or rating == "U*"
  end


  protected
  def uniquify
    SectionOutcomeRating.where(section_outcome_id: section_outcome_id, student_id: student_id).each do |a|
      a.destroy unless a.id == id
    end
  end
end
