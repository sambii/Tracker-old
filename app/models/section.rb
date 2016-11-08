# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class Section < ActiveRecord::Base
  # Access Control
  # using_access_control

  # Relationships
  has_many                        :teaching_assignments,
                                  dependent: :destroy
  accepts_nested_attributes_for   :teaching_assignments
  has_many                        :teachers, through: :teaching_assignments
  belongs_to                      :subject
  has_one                         :school, through: :subject
  has_many                        :enrollments,
                                  include: :student,
                                  conditions: { users: { active: true } },
                                  dependent: :destroy
  accepts_nested_attributes_for   :enrollments
  has_many                        :students, through: :enrollments,
                                  order: [:last_name, :first_name]
  has_many                        :section_outcomes,
                                  conditions: { active: true },
                                  order: :position,
                                  dependent: :destroy
  has_many                        :inactive_section_outcomes,
                                  class_name: 'SectionOutcome',
                                  conditions: { active: false},
                                  order: :position
  has_many                        :subject_outcomes, through: :section_outcomes,
                                  conditions: {'subject_outcomes.active' => true}
  has_many                        :all_subject_outcomes, through: :section_outcomes
  has_many                        :section_outcome_ratings, through: :section_outcomes
  has_many                        :evidences, conditions: { active: true }
                                  accepts_nested_attributes_for :evidences
  has_many                        :inactive_evidences, class_name: 'Evidence', conditions: { active: false }
  has_many                        :evidence_section_outcomes,
                                  through: :section_outcomes
                                  accepts_nested_attributes_for :inactive_evidences
  has_many                        :evidence_section_outcome_ratings,
                                  include: :evidence,
                                  through: :evidence_section_outcomes
  belongs_to                      :school_year

  # Scopes
  scope                 :current, { include: { subject: :school }, conditions: ["sections.school_year_id = schools.school_year_id"] }
  scope                 :old,     { include: { subject: :school }, conditions: ["sections.school_year_id != schools.school_year_id"] }

  def active_student_enrollments
   enrollments.where(
      active: true,
      users: {active: true}
    )
  end



  # Validations
  validates_presence_of :line_number, :subject_id, :school_year_id
  validate              :subject_and_section_in_same_school_year, on: :create

  def subject_and_section_in_same_school_year
    unless self.school_year == self.subject.school.current_school_year
      errors.add(:school_year, "must be the same for this section and this section's subject.school")
    end
  end

  # Defines the set of students enrolled in the class where the enrollment is
  # flagged as active in the database. Ordered alphabetically.
  def active_evidences
    Evidence.joins(:section_outcome).where(
      :section_outcomes => {
        :section_id => id,
        :active => true
      },
      :active => true
    ).order(:position)
  end

  def active_students(options = {})
    where_clause = {
      active: true,
      enrollments: {
        section_id: id,
        active: true
      }
    }
    where_clause[:enrollments][:subsection] = options[:subsection] if options[:subsection].to_i > 0

    if options[:by_first_last]
      return_value = Student.joins(enrollments: :student).where(where_clause).order([:xid, :first_name, :last_name])
    else
      return_value = Student.joins(enrollments: :student).where(where_clause).order([:last_name, :first_name])
    end
  end

  # To populate the list of subsections that will appear on section#show.
  def subsections
    (Enrollment.where(section_id: id).pluck(:subsection).uniq - [0]).sort.map { |a| [ALPHABET[a], a] }
  end

  # Returns a hash of section outcome ratings hash[section_outcome_id][student_id] = rating
  # If a rating doesn't exist, returns "".
  # used only in the Teacher Tracker page, and Bulk Rate pages.
  def hash_of_section_outcome_ratings
    return_value            = Hash.new { |l, k| l[k] = Hash.new(["",0]) }
    section_outcome_ratings = SectionOutcomeRating.select("section_outcome_ratings.id, section_outcome_ratings.rating, section_outcome_ratings.student_id, section_outcome_ratings.section_outcome_id").joins({:student => :enrollments}, {:section_outcome => :section}).where(
                                :section_outcomes => {
                                    :section_id => id
                                    },
                                  :enrollments => {
                                    :section_id => id
                                  }
                              ).all
    section_outcome_ratings.each do |s|
      return_value[s[:section_outcome_id]][s[:student_id]] = [s[:rating],s[:id]]
    end
    return_value
  end

  def hash_of_evidence_ratings(options = {})
    return_value      = Hash.new { |h,k| h[k] = Hash.new { |l,m| l[m] = Hash.new(["", "", 0, "f"]) } }
    if options[:evidence_id].present?
      evidence_ratings  = evidence_section_outcome_ratings.joins(:student)
        .includes(:evidence_section_outcome)
        .where(
          users: {active: true},
          evidence_section_outcomes: {evidence_id: options[:evidence_id]}
        )
    else
      evidence_ratings  = evidence_section_outcome_ratings.joins(:student)
        .includes(:evidence_section_outcome)
        .where(users: {active: true})
    end
    Rails.logger.debug ("*** got evidence ratings")
    evidence_ratings.each do |e|
      # e[:rating] = "U" if e[:rating] == ""
      e[:rating] = "" if e[:rating] == nil
      return_value[e.evidence_section_outcome.section_outcome_id][e.evidence_section_outcome.evidence_id][e.student_id] = [e[:rating], e[:comment], e[:id],e[:flagged].to_s[0]]
    end
    return_value
  end

  def hash_of_active_evidences
    return_value            = Hash.new { |h,k| h[k] = Array.new }
    evidences               = Evidence.joins(:section_outcome).where(
                                :section_outcomes => {
                                  :section_id     => id,
                                  :active         => true
                                },
                                :active           => true
                              ).order(
                                :position
                              )
    evidences.each do |e|
      return_value[e.section_outcome_id] << [e.id, e.name, e.assignment_date]
    end
    return_value
  end

  def name
    subject.name
  end

  def full_name
    subject.name + ": " + line_number
  end

  def teacher_names
    teachers.sort { |a,b| a.last_name_first <=> b.last_name_first }.map \
                  { |a|   a.full_name }.to_sentence
  end

  def rated_section_outcomes_count
    SectionOutcomeRating.where(section_outcome_id: section_outcomes.pluck(:id), rating: ['H', 'P', 'N']).select('DISTINCT section_outcome_ratings.section_outcome_id').count
  end
  def rated_evidence_section_outcomes_count
    eso_ids = EvidenceSectionOutcome.where(section_outcome_id: section_outcomes.pluck(:id))
    EvidenceSectionOutcomeRating.where(evidence_section_outcome_id: eso_ids, rating: ['B', 'G', 'Y', 'R', 'M']).select('DISTINCT evidence_section_outcome_ratings.evidence_section_outcome_id').count
  end

  def count_ratings_by_outcome
    return_value      = Hash.new { |l, k| l[k] = Hash.new(0) }
    section_outcomes  = SectionOutcome.includes(:subject_outcome, {section_outcome_ratings: :student}).where(:section_id => id)

    section_outcomes.each do |section_outcome|
      section_outcome.section_outcome_ratings.each do |section_outcome_rating|
        unless section_outcome_rating.rating == "U"
          return_value[section_outcome.subject_outcome.id][section_outcome_rating.rating] += 1 if section_outcome_rating.student.active
        end
      end
    end
    return_value
  end

  # used in New UI for Generate Reports
  def count_ratings
    section_outcome_ratings = SectionOutcomeRating.joins({student: :enrollments}, :section_outcome).where(enrollments: {active: true, section_id: id }, section_outcomes: { section_id: id })
    return_value = Hash.new(0)
    ["H", "P", "N", "U"].each do |rating|
      return_value[rating] = 0
    end
    section_outcome_ratings.each do |section_outcome_rating|
      unless section_outcome_rating.rating.nil?
        return_value[section_outcome_rating.rating[0]] += 1
      end
    end
    return_value
  end

  def count_of_rated_evidence_section_outcomes
    count = 0
    evidence_section_outcomes.map { |a| count += 1 if a.rated? }
    return count
  end

  def grading_algorithm
    school.grading_algorithm
  end

  def grading_scale
    school.grading_scale
  end

  # TODO: Experimental stuff! Yikes!
  def data_array student_ids = active_students.map {|a| a.id }

    #SectionOutcomeRating.where(student_id: student_ids, section_outcome_id: section_outcome_ids).uniq.each do |rating|
    #
    #end
    section_outcomes_array = SectionOutcome.includes(
      :section_outcome_ratings, { evidence_section_outcomes: [:evidence, :evidence_section_outcome_ratings] }
    ).where(
      section_outcomes: { section_id: id, active: true },
      evidences: { active: true },
      evidence_section_outcome_ratings: { student_id: student_ids },
      section_outcome_ratings: { student_id: student_ids }
    ).order("section_outcomes.position, evidence_section_outcomes.position")
    data = Array.new(section_outcome_ids.size) { [Array.new(student_ids.size) { ["U", 0] }, []] }
    section_outcomes_array.each_with_index do |section_outcome, i|
      section_outcome.section_outcome_ratings.each do |rating|
        data[i][0][student_ids.index(rating.student_id)] = [rating.rating, rating.id]
      end
      section_outcome.evidence_section_outcomes.each_with_index do |evidence_section_outcome, j|
        data[i][1][j] = Array.new(student_ids.size, ["", "", 0, "f"])
        evidence_section_outcome.evidence_section_outcome_ratings.each do |rating|
          data[i][1][j][student_ids.index(rating.student_id)] = [rating.rating, rating.comment, rating.id, rating.flagged]
        end
      end
    #evidence_section_outcome_ids = evidence_section_outcomes.map { |a| a.id }
    #evidence_section_outcomes.each do |evidence_section_outcome|
    #  data[section_outcome_ids.index(evidence_section_outcome.section_outcome_id)][1] = Array.new(evidence_section_outcomes.size) { Array.new(student_ids.size) { ["", "", 0, "f"] } }
    #  evidence_section_outcome.evidence_section_outcome_ratings.each do |rating|
    #    data[section_outcome_ids.index(evidence_section_outcome.section_outcome_id)][1][evidence_section_outcome_ids.index(rating.evidence_section_outcome_id)][student_ids.index(rating.student_id)] = [rating.rating, rating.comment.present?, rating.id, rating.flagged?]
    #  end
    end
    data
  end

  def array_of_evidence_section_outcome_ratings
    evidence_section_outcome_ids = evidence_section_outcomes.pluck("evidence_section_outcomes.id")
  end
end
