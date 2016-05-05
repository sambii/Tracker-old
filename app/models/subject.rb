# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class Subject < ActiveRecord::Base
  # Access Control
  # using_access_control

  # Relationships
  belongs_to                    :subject_manager,   # rails 4 only - required: false,
                                class_name: "User"
  belongs_to                    :discipline
  belongs_to                    :school
  has_many                      :sections,
                                dependent: :destroy
  has_many                      :teachers,
                                through: :teaching_assignments
  has_many                      :subject_outcomes,
                                conditions: { active: true }
  has_many                      :all_subject_outcomes,
                                class_name: 'SubjectOutcome',
                                dependent: :destroy
  accepts_nested_attributes_for :subject_outcomes,
                                :reject_if  => lambda {|a| a[:name].blank?}

  # Validations
  validates_presence_of :school, :discipline, :name


  # New UI
  # for Proficiency Bar charts and Progress meters by Subject (for School Administrator)
  # hash returns fields to sort on
  def count_ratings_plus(options = {})
    cur_section_ids = options[:section_ids].present? ? options[:section_ids] : []
    school_year_starts_at = options[:school_year_starts_at].present? ? options[:school_year_starts_at] : Date.today
    ratings = { H: 0, P: 0, N: 0, U: 0 }
    sor_los = []
    all_los = []
    last_rating_date = school_year_starts_at

    section_outcomes = SectionOutcome.where(active: true, section_id: cur_section_ids)

    section_outcome_ratings = SectionOutcomeRating.includes(:section_outcome).where(
      :section_outcomes => {
        :active => true,
        section_id: cur_section_ids
      }
    )
    section_outcome_ratings.each do |sor|
      rating = sor.rating
      unless rating.nil? && rating.length > 0 # make sure we have a value
        # make sure we only use the first character, just in case
        ratings[rating[0].to_sym] += 1 if ['H','P','N','U'].include?(rating[0])
        # update the last rating date for this subject
        last_rating_date = sor.updated_at if sor.updated_at > last_rating_date
        # update the list of LOs that have ratings for this subject (for a count)
        sor_los << sor.section_outcome_id if !sor_los.include?(sor.section_outcome_id)
      end
    end

    all_los_count = section_outcomes.count

    ratio = (all_los_count > 0) ? (sor_los.count.to_f / all_los_count) : 0

    return {ratings: ratings, rated_los_count: sor_los.count, all_los_count: all_los_count, last_rating_date: last_rating_date, subject: self, ratio: ratio}
  end


  # New UI
  # for Proficiency Bar charts and Progress meters by Section (for Subject)
  # get section ratings by various orders
  def count_section_ratings_plus(options = {})
    cur_section_ids = options[:section_ids].present? ? options[:section_ids] : []
    school_year_starts_at = options[:school_year_starts_at].present? ? options[:school_year_starts_at] : [Date.today]
    opt_sz = options[:skip_zeros]
    skip_zeros = (opt_sz.present? && opt_sz.is_a?(TrueClass)) ? options[:skip_zeros] : false
    section_ratings = Hash.new
    cur_section_ids.each do |s|
      ratings = { H: 0, P: 0, N: 0, U: 0 }
      sor_los = []
      all_los = []
      last_rating_date = school_year_starts_at.to_date

      section_outcomes_count = SectionOutcome.where(active: true, section_id: s).count

      section_outcome_ratings = SectionOutcomeRating.includes(:section_outcome).where(
        :section_outcomes => {
          :active => true,
          section_id: s
        }
      )
      section = Section.find(s)
      section_outcome_ratings.each do |sor|
        rating = sor.rating

        unless rating.nil? && rating.length > 0 # make sure we have a value
          # make sure we only use the first character, just in case
          ratings[rating[0].to_sym] += 1 if ['H','P','N','U'].include?(rating[0])
          # update the last rating date for this subject
          last_rating_date = sor.updated_at if sor.updated_at > last_rating_date
          # update the list of LOs that have ratings for this subject (for a count)
          sor_los << sor.section_outcome_id if !sor_los.include?(sor.section_outcome_id)
        end
      end

      # all_los_count = section_outcomes.all.size

      if section_outcomes_count > 0 || !skip_zeros
        by_count_ratio = sor_los.count.to_f / section_outcomes_count.to_f
        total_ratings = ratings[:H] + ratings[:P] + ratings[:N] + ratings[:U]
        by_nyp_ratio = total_ratings == 0 ? 0 : ( (ratings[:N] + ratings[:U]) / total_ratings ).to_f
        section_ratings[s] = {ratings: ratings, rated_los_count: sor_los.count, all_los_count: section_outcomes_count, last_rating_date: last_rating_date, section: section, by_count_ratio: by_count_ratio, by_nyp_ratio: by_nyp_ratio}
      end
    end
    return section_ratings
  end


  def count_ratings_by_outcome
    return_value      = Hash.new { |l, k| l[k] = Hash.new(0) }
    section_outcomes  = SectionOutcome.includes(
      :section_outcome_ratings
    ).joins(
      :section
    ).where(
      :sections       => {
        :subject_id   => id
      }
    )

    section_outcomes.each do |section_outcome|
      section_outcome.section_outcome_ratings.each do |section_outcome_rating|
        unless section_outcome_rating.rating == "U"
          return_value[section_outcome.subject_outcome.id][section_outcome_rating.rating] += 1
        end
      end
    end
    return_value
  end

  def subject_name_without_grade
    # assumes the school is set to have subject names with a space and grade level appended to them
    # see school.rb has_flag?(School::GRADE_IN_SUBJECT_NAME)
    name_split = read_attribute(:name).split(/ /)
    # note, if name_split length is 1, then there is no grade in the name
    return (name_split.length > 1) ? name_split.first(name_split.length - 1).join(' ') : name_split[0]
  end

  def grade_from_subject_name
    name_split = read_attribute(:name).split(/ /)
    grade_semester = (name_split.length > 1) ? name_split[name_split.length - 1] : ''
    grade_semester_split = grade_semester.split(/[[:alpha:]]/)
    return (grade_semester_split.length > 0) ? grade_semester_split[0] : ''
  end

end
