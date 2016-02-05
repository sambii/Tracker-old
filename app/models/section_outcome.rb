# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SectionOutcome < ActiveRecord::Base
  # Access Control
  # using_access_control

  # Relationships
  belongs_to                    :subject_outcome
  belongs_to                    :section

  has_many                      :section_outcome_ratings,
                                :dependent  => :destroy
  accepts_nested_attributes_for :section_outcome_ratings,
                                :reject_if  => lambda { |a| a[:rating].blank? }
  has_many                      :evidence_section_outcomes,
                                include: :evidence,
                                conditions: {evidences: { active: true } }
  has_many                      :evidences,
                                through: :evidence_section_outcomes
  has_many                      :inactive_evidences,
                                through: :evidence_section_outcomes,
                                source: :evidence,
                                conditions: {active: false}
  has_many                      :evidence_section_outcome_ratings,
                                through: :evidence_section_outcomes
  has_many                      :section_outcome_attachments,
                                dependent: :destroy

  # Validations
  validate                      :consistent_subject_id
  validates_uniqueness_of       :subject_outcome_id,
                                :scope      => :section_id,
                                :message    => "This learning outcome already exists in this section!"
  validates_inclusion_of        :marking_period,
                                :in         => lambda { |sect| Range::new(1,sect.max_bitmask) }, #max bitmask changes based on school.marking_period
                                :message    => "Bitmask must be computed to a number between 1 and max_bitmask",
                                on: :create # allow the bitmask to remain wrong on update, so other learning outcome attributes can be changed
                                            # in the case where school marking period gets changed. Normalization happens in #marking_period_array method
                                            # Right now we think that schools will rarely change their marking period. If this becomed a common practice
                                            # in the future, we will consider moving school#marking_period to school_year#marking_period.

  # Other Definitions
  acts_as_list(scope: :section)

  def consistent_subject_id
    unless section.subject_id == subject_outcome.subject_id
      self.errors.add(:base, "This outcome is from a different subject!")
    end
  end

  def essential
    subject_outcome.essential
  end

  def self.find_or_create search_attributes, attributes
    @section_outcome = SectionOutcome.where(search_attributes).first
    if @section_outcome
      @section_outcome.attributes = attributes
    else
      @section_outcome = SectionOutcome.new attributes
    end
    return @section_outcome
  end

  def hash_of_evidence_ratings options = {}
    if options[:reverse_keys]
      return_value      = Hash.new { |h,k| h[k] = Hash.new(["", ""]) }
      evidence_ratings  = EvidenceSectionOutcomeRating.where(section_outcome_id: id)
      evidence_ratings.each do |e|
        return_value[e.student_id][e.evidence_id] = [e[:rating],e[:comment]]
      end
      return return_value
    end
    return_value      = Hash.new { |h,k| h[k] = Hash.new(["", ""]) }
    evidence_ratings  = EvidenceSectionOutcomeRating.where(section_outcome_id: id)
    evidence_ratings.each do |e|
      return_value[e.evidence_id][e.student_id] = [e[:rating],e[:comment]]
    end
    return_value
  end

  def hash_of_ratings options = {}
    return_value = Hash.new { |h,k| h[k] = "U" }
    section_outcome_ratings = SectionOutcomeRating.where(section_outcome_id: id)
    section_outcome_ratings.each do |s|
      return_value[s.student_id] = { rating: s.rating, id: s.id }
    end
    return_value
  end

  def name
    subject_outcome.name
  end

  def shortened_name
    n = name
    if n.length > 40
      n = name[0..39] + "..."
    end
    return n
  end

  def marking_period_set? mp_num
    # force marking period number to sane number
    if mp_num > self.section.school.marking_periods
      mp_num_work = self.section.school.marking_periods - 1
    elsif mp_num < 1
      mp_num_work = 0
    else
      mp_num_work = mp_num - 1
    end
    return ((2**mp_num_work & self.marking_period) > 0) ? true : false
  end


  # method to generate an array of marking periods from the marking_period field
  def marking_period_array
    # max_bitmask is the maximum allowed bitwise value for a giving Integer marking period
    # the current marking period may changed by the user
    # bitwise AND operation done here so that the bitmast is adjusted properly to not contain
    # semesters greated than the mask. This value is recalulated only when the user changes selected
    # marking periods.
    bitmask = marking_period & max_bitmask
    array = []
    index = self.section.school.marking_periods
    while bitmask > 0
      if bitmask - (2 ** (index - 1)) >= 0
        array << index
        bitmask -= (2 ** (index - 1))
      end
      index -= 1
    end
    array = array.sort
    return array
  end

  # method to generate the marking period field value from the marking_period array
  def marking_period_bitmask! array
    bitmask = 0
    array.each do |marking_period|
      bitmask += 2 ** (marking_period - 1)    # Scales for any number of marking periods.
    end
    self.marking_period = bitmask
  end

  #this is the maximum allowed bitwise value for a given Integer marking period
  def max_bitmask
    periods = self.section.school.marking_periods
    (2 ** periods) - 1
  end

  def count_ratings
    section_outcome_ratings = SectionOutcomeRating.joins({student: :enrollments}, :section_outcome).where(enrollments: {active: true, section_id: section_id }, section_outcomes: { id: id })
    return_value = Hash.new(0)
    return_value["H"] = 0
    return_value["P"] = 0
    return_value["N"] = 0
    return_value["U"] = 0
    section_outcome_ratings.each do |section_outcome_rating|
      unless section_outcome_rating.rating.nil?
        return_value[section_outcome_rating.rating[0]] += 1
      end
    end
    return nil if return_value == {}
    return_value
  end

  def students_by_rating rating
    array = []
    section_outcome_ratings.map { |a|
     array << { last_name: a.student.last_name, first_name: a.student.first_name } if a.rating == rating
    }
    array
  end

end
