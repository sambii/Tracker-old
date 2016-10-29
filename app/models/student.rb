# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class Student < User

  # parameter black/white listing
  attr_accessor :subsection

  # before_update :set_unique_username, if: lambda { |a| a.active }
  # after_update :update_parent_username, if: lambda { |a| a.active }
  after_create :create_parent

  # Access Control
  # using_access_control

  # Relationships
  has_many                      :parents, foreign_key: 'child_id', dependent: :destroy
  has_one                       :parent, foreign_key: 'child_id'
  accepts_nested_attributes_for :parents
  belongs_to                    :school
  has_one                       :first_enrollment, class_name: "Enrollment", foreign_key: 'student_id'
  has_many                      :enrollments,
                                conditions: { active: true },
                                dependent: :destroy
  accepts_nested_attributes_for :enrollments
  has_many                      :sections,
                                through: :enrollments
  has_many                      :current_sections,
                                through: :enrollments,
                                source: :section,
                                conditions: {
                                  enrollments: { active: true }
                                }


  has_many                      :section_outcome_ratings,
                                dependent: :destroy
  has_many                      :attendances,
                                foreign_key: :user_id   # needed to eager load attendances, to prevent error: Mysql2::Error: Unknown column 'attendances.student_id' in 'where clause':  ?? todo ?? - is this still needed?

  # Validations

  validates_presence_of         :grade_level
  validates_numericality_of     :grade_level

  validate :is_email_required?
  validate :is_grade_level_valid?

  # Gender is not required
  # validates                     :gender, presence: {message: I18n.translate('errors.cant_be_blank')}
  # validates_length_of           :gender,
  #                               maximum: 1, message: I18n.translate('item_is_invalid')


  #scopes
  default_scope where(student: true)
  scope :active, where(active: true)
  scope :active_student, where(active: true)
  scope :special_ed_status, lambda { |statuses| where(special_ed: statuses) }
  scope :alphabetical, where(active: true).order("last_name", "first_name")
  scope :first_last, order("first_name", "last_name")


  # other definitions
  def active_sections
   sections.where(
      :enrollments        => {
        :active           => true,
        :student_id       => id
      }
    )
  end

  def cur_yr_enrollments
   enrollments.where(
      sections: {
        school_year_id: school.school_year_id
      },
      student_id: id,
      active: [true, false]
    )
  end

  # TODO: Refactor so that it only pulls ratings for one section / subject.
  def active_section_outcome_ratings
    SectionOutcomeRating.joins(:section_outcome).where(
      :section_outcomes   => {
        :active           => true
      },
      :student_id         => id
    )
  end

  def get_parent
    Parent.where(child_id: id, school_id: school_id).first
  end

  def create_parent
    parent = Parent.new(child_id: id)
    parent.school_id = school_id
    parent.set_unique_username
    parent.set_temporary_password
    parent.save
  end

  # New UI - Student Dashboard page
  def hash_of_section_outcome_rating_counts(options = {})
    options[:marking_periods] ||= (1..10).to_a
    hash = Hash.new { |h,k| h[k] = { H: 0, P: 0, N: 0, U: 0 } }
    section_outcome_ratings = SectionOutcomeRating.joins(:section_outcome).where(student_id: id, section_outcomes: { active: true })
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

  # Oh, boy.
  def import_subject_outcome_ratings! subject_id, new_section_id
    new_section          = Section.find new_section_id
    new_section_outcomes = new_section.section_outcomes
    existing_sections    = sections.where(:subject_id => subject_id)
    subject_outcome_rating_hash = {}

    existing_sections.each do |existing_section|
      unless existing_section == new_section
        ratings = SectionOutcomeRating.includes(:section_outcome).where(:student_id => id, :section_outcomes => {:section_id => existing_section.id})
        ratings.each do |rating|
          if subject_outcome_rating_hash[rating.section_outcome.subject_outcome_id]
            subject_outcome_rating_hash[rating.section_outcome.subject_outcome_id] = rating if rating > subject_outcome_rating_hash[rating.section_outcome.subject_outcome_id]
          else
            subject_outcome_rating_hash[rating.section_outcome.subject_outcome_id] = rating
          end
        end
      end
    end

    new_section_outcomes.each do |new_section_outcome|
      rating = subject_outcome_rating_hash[new_section_outcome.subject_outcome_id]
      if subject_outcome_rating_hash[new_section_outcome.subject_outcome_id]
        new_rating = SectionOutcomeRating.new(
          :rating     => (rating.rating[0,1] + "*"),
          :student_id => id,
          :section_outcome_id => new_section_outcome.id
        )
        new_rating.save
      end
    end
    true
  end

  def section_evidence_ratings section_id
    hash = Hash.new { |h,k| h[k] = { rating: "", comment: nil, flagged: false } }
    EvidenceSectionOutcomeRating.joins(:evidence).where(
      student_id: id,
      evidences: { section_id: section_id, active: true }
    ).map { |a| hash[a.evidence_section_outcome_id] = { rating: a.rating, comment: a.comment, flagged: a.flagged } }
    hash
  end

  # New UI for Student Dashboard Summary Evidence Stats
  def missing_evidences_by_section
    # hash of sections by enrollment id
    hash = Hash.new{ |h,k| h[k] = { enroll_id: nil, subject: '', section: '', evid_hash: nil, count: 0} }
    # hash of evidences by sequence of evidences for section
    Enrollment.includes(:section).current.where(student_id: id).each do |ae|
      enroll_id = ae.id
      subject = ae.section.name
      section = ae.section.line_number
      evid_hash = Hash.new{ |h,k| h[k] = { evid_name: '', type: '', date: '' } }
      # get all missing evidences for section
      section_evidence_ratings_of_rating(ae.section_id, 'M').each_with_index do |esor, eix|
        # get evidence_id to ensure that only one entry is saved per Evidence
        # - we dont want the evidence duplicated if it is in multiple LOs
        evidence_id = esor.evidence_section_outcome.evidence_id
        evid_hash[evidence_id] = {
          evid_name: esor.evidence_section_outcome.name,
          type: esor.evidence_section_outcome.evidence_type.name,
          date: esor.evidence_section_outcome.assignment_date
        }
      end
      has_teach = ae.section && ae.section.teachers && ae.section.teachers.first
      t_last_name = (has_teach) ? ae.section.teachers.first.last_name : ''
      t_first_name = (has_teach) ? ae.section.teachers.first.last_name : ''
      hash[ae.id] = {enroll_id: enroll_id, subject: subject, section: section, teacher_lname: t_last_name, teacher_fname: t_first_name, evid_hash: evid_hash, count: evid_hash.count}
    end
    hash
  end

  # New UI for Student Dashboard Summary Evidence Stats
  # should this be refactored to pull all ratings?
  def section_evidence_ratings_of_rating(section_id, rating)
    EvidenceSectionOutcomeRating.includes(:evidence).where(
      student_id: id,
      rating: rating,
      evidences: { section_id: section_id, active: true }
    )
  end

  # New UI for Student Dashboard Summary Evidence Stats
  def count_section_evidence_ratings section_id, start_date=nil
    hash = {'B' => 0, 'G' => 0, 'Y' => 0, 'R' => 0, 'M' => 0, 'U' => 0}
    query = EvidenceSectionOutcomeRating.joins(:evidence).where(
      student_id: id,
      evidences: { section_id: section_id, active: true }
    )
    if start_date.present?
      query = query.where(updated_at.to_date >= start_date.to_date)
    end
    if start_date.present?
      as_date = start_date.to_date
      query = query.where(updated_at: as_date..1.day.from_now.to_date)
    end
    query.each do |esor|
      Rails.logger.debug("*** esor: #{esor.inspect.to_s}")
      if !esor.rating.nil? && esor.rating.length > 0
        if hash["#{esor.rating[0]}"]
          hash["#{esor.rating[0]}"] += 1
        else
          hash["#{esor.rating[0]}"] = 1
        end
      end
    end
    Rails.logger.debug("*** hash: #{hash.inspect.to_s}")
    hash
  end

  # New UI for Student Dashboard Summary Evidence Stats
  def overall_current_evidence_ratings start_date=nil
    hash = {'B' => 0, 'G' => 0, 'Y' => 0, 'R' => 0, 'M' => 0, 'U' => 0}
    ty_sections ||= current_sections.where(school_year_id: school.school_year_id)
    ty_sections.each do |tys|
      hash.merge!(count_section_evidence_ratings(tys, start_date)){ |key, oldval, newval| oldval + newval}
    end
    hash
  end

  def section_grade section_id
    section = Section.find(section_id)
    ratings = section_section_outcome_ratings(section_id)
    h = ratings.count { |a| a[1] == "H" }
    p = ratings.count { |a| a[1] == "P" }
    n = ratings.count { |a| a[1] == "N" }
    t = ratings.count { |a| a[1] != "U" }
    algorithm = section.grading_algorithm
    scale     = section.grading_scale.sort

    algorithm.gsub!("H", "#{h}.to_f")
    algorithm.gsub!("P", "#{p}.to_f")
    algorithm.gsub!("N", "#{n}.to_f")
    algorithm.gsub!("T", "#{t}.to_f")
    unless t == 0
      raw_score = eval(algorithm)
      letter_grade = ""
      scale.each do |grade|
        letter_grade = grade[1] if raw_score >= grade[0]
      end
      return letter_grade
    else
      return "N/A"
    end
  end

  def update_parent_username
    parents.each do |parent|
      parent.set_unique_username
      parent.save
    end
  end

  # Used in New UI by nyp_student
  def section_outcomes_by_rating rating, section_id
    array = []
    SectionOutcomeRating.joins(
      :section_outcome
    ).where(
      rating: rating,
      student_id: id,
      section_outcomes: {
        section_id: section_id,
        active: true
      }
    ).order(:position).map { |a|
      array << { id: a.section_outcome.id, name: a.section_outcome.name } if a.rating[0] == rating
    }
    array
  end

  def section_section_outcome_ratings section_id
    hash = Hash.new { |h,k| h[k] = "U" }
    SectionOutcomeRating.joins(:section_outcome).where(
      student_id: id,
      section_outcomes: { active: true, section_id: section_id }
    ).map { |a| hash[a.section_outcome_id] = a.rating }
    hash
  end

  def count_of_section_evidence_section_outcome_ratings section_id
    hash = Hash.new { |h,k| h[k] = 0 }
    EvidenceSectionOutcomeRating.joins(
      evidence_section_outcome: :evidence
    ).where(evidences: {section_id: section_id, active: true}, student_id: id).map { |a|
      hash[a.rating] += 1
    }
    hash
  end

  def ratings_count rating
    section_ids ||= current_sections.where(school_year_id: school.school_year_id).pluck("sections.id")
    if ["H", "P", "N", "U"].include? rating
      SectionOutcomeRating.joins(:section_outcome).where(student_id: id, section_outcomes: { active: true, section_id: section_ids }, rating: ["#{rating}", "#{rating}*"]).count
    end
  end

  def learning_outcomes_by_rating rating, section_ids = nil
    section_ids ||= current_sections.where(school_year_id: school.school_year_id).pluck("sections.id")
    if ["H", "P", "N", "U"].include? rating
      SectionOutcomeRating.joins(:section_outcome).where(student_id: id, section_outcomes: { active: true, section_id: section_ids }, rating: ["#{rating}", "#{rating}*"]).map { |a| a.section_outcome }
    end
  end

  def subsection
    if first_enrollment.try(:subsection).present?
      ALPHABET[first_enrollment.subsection]
    else
      ""
    end
  end

  def subsection= subsection
    if subsection.present?
      subsection = ALPHABET.index(subsection) if ALPHABET.include? subsection
      if subsection.try(:to_i).is_a? Integer
        enrollments.current.update_all(subsection: subsection)
      end
    end
  end

  def is_email_required?
    email_error = false
    begin
      if self.school_id.present?
        school = School.find(self.school_id)
        if school.has_flag?(School::USERNAME_FROM_EMAIL) && self.email.blank?
          self.errors.add(:email, 'Email is required.')
          email_error = true
        end
      end
    rescue
      Rails.logger.error("ERROR: is_email_required? school (#{self.school_id.inspect}) find error.")
    end
    return email_error
  end

  def is_grade_level_valid?
    grade_level_error = false
    begin
      if self.school_id.present?
        school = School.find(self.school_id)
        if school.has_flag?(School::USER_BY_FIRST_LAST) && (self.grade_level.blank? || self.grade_level > 3)
          self.errors.add(:grade_level, 'Grade Level is invalid')
          grade_level_error = true
        end
      end
    rescue
      Rails.logger.error("ERROR: is_email_required? school (#{self.school_id.inspect}) find error.")
    end
    return grade_level_error
  end

end
