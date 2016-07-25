# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class School < ActiveRecord::Base

  # Flags constant values:
  USE_FAMILY_NAME = 'use_family_name'
  USER_BY_FIRST_LAST = 'user_by_first_last'
  GRADE_IN_SUBJECT_NAME = 'grade_in_subject_name'
  USERNAME_FROM_EMAIL = 'username_from_email'
  VALID_FLAGS = [USE_FAMILY_NAME, USER_BY_FIRST_LAST, GRADE_IN_SUBJECT_NAME, USERNAME_FROM_EMAIL]
  # VALID_FLAGS_NAMES = ['Surname', 'User Sort by','Grade in Subject Name','Username from email']
  # VALID_FLAGS_VALUES = ['Use Family Name','First/Last','Yes','Yes']
  # Access Control
  # using_access_control
  # attr_accessible :flag_par
  attr_accessible :name, :acronym, :city, :marking_periods, :school_year, :flag_pars

  # Relationships
  has_many                      :teachers,
                                :dependent => :destroy
  has_many                      :counselors,
                                :dependent => :destroy
  has_many                      :subjects,
                                :dependent => :destroy
  has_many                      :sections,
                                :through   => :subjects
  has_many                      :students,
                                conditions: { active: true },
                                :dependent => :destroy

  # remove this? once automated testing is set up
  has_many                      :school_years

  belongs_to                    :school_year

  accepts_nested_attributes_for :students# ,
                                # :reject_if => lambda {|a| a[:first_name].blank? and a[:subsection].blank? }

  # Validations
  validates_presence_of         :name,
                                :acronym,
                                :city
  validates_uniqueness_of       :name,
                                :acronym

  validates_inclusion_of        :marking_periods,
                                :in => 1..6,
                                :message => "Marking Periods must be between 1 and 6."

  validates_numericality_of     :marking_periods,
                                only_integer: true,
                                message: "Marking Periods must be an Integer value."
  validate                      :consistent_school_year

  # Other Definitions
  serialize                     :grading_scale, Array


  # Flags
  # List of valid flags are in here!
  def valid_flag?(flag)
    VALID_FLAGS.include?(flag.to_s)
  end

  def has_flag?(flag)
    (self.flags || '').split(',').include?(flag.to_s)
  end

  def add_flag(flag)
    Rails.logger.debug("*** add_flag: #{flag}")
    # Note: does not save
    flag_a = (self.flags || '').split(',')
    if self.valid_flag?(flag) && !flag_a.include?(flag.to_s)
      self.flags = (flag_a << flag.to_s).join(',')
      return true
    else
      return false
    end
  end

  def remove_flag(flag)
    Rails.logger.debug("*** remove_flag: #{flag}")
    # Note: does not save
    flag_a = (self.flags || '').split(',')
    if flag_a.include?(flag.to_s)
      self.flags = (flag_a - ([] << flag.to_s)).join(',')
      return true
    else
      return false
    end
  end

  def flag_pars=(pars)
    Rails.logger.debug("*** flag_pars: #{pars.inspect}")
    pars.each do |p,v|
      if ['on', 'true'].include?(v.to_s)
        add_flag(p)
      elsif ['off', 'false'].include?(v.to_s)
        remove_flag(p)
      else
        Rails.logger.error('ERROR: Invalid flag #{p} -> #{v}')
      end
    end
    Rails.logger.debug("*** self.flags: #{self.flags}")
  end


  # [student_id][section_outcome_id] = {"R"}
  def hash_of_section_outcome_ratings
    hash = Hash.new { |l, k| l[k] = Hash.new("U") }
    SectionOutcomeRating.joins(section_outcome: {section: :subject}).where(subjects: {school_id: id}).map { |a|
      hash[a.student_id][a.section_outcome_id] = a.rating
    }
    hash
  end

  def hash_of_evidence_ratings
    hash = Hash.new { |h,k| h[k] = Hash.new(rating: "U", comment: "") }
    EvidenceSectionOutcomeRating.joins(evidence_section_outcome: {evidence: {section: :subject}}).where(subjects: {school_id: id}).map { |a|
      hash[a.student_id][a.evidence_section_outcome_id] = {rating: a.rating, comment: a.comment}
    }
    hash
  end

  # returns the current school year
  def current_school_year
    self.school_year_id.blank? ? nil : SchoolYear.find(self.school_year_id)
  end

  # use this to change the current school year, e.g. for school_year roll over
  # the argument can be either a school_year_id, or an instance of SchoolYear
  def current_school_year=(school_year_id_or_object)
    object = school_year_id_or_object
    if object.is_a? Fixnum # school year id was passed in
      self.school_year_id = object
    elsif object.is_a? SchoolYear
      self.school_year_id = object.id
    else
      errors.add(:school_year,"unable to handle the passed in argument")
    end
  end

  def prior_school_year
    csy = self.current_school_year
    if csy
      psy_name = "#{csy.starts_at.year-1}-#{csy.ends_at.year-1}"
      psys = SchoolYear.where(name: psy_name, school_id: csy.school_id)
      if psys.count == 1
        psy = psys.first
      else
        psy = nil
      end
    else
      psy = nil
    end
    return psy
  end

  # validation helper to ensure that self.id is the same as school_year.school_id
  # when assigning a school_year
  def consistent_school_year
    unless self.school_year_id.blank?
      unless SchoolYear.find(self.school_year_id).school_id == self.id
        errors.add(:school_year_id, "the school year is not assigned to this school")
      end
    end
  end

  # This method returns a count of all of the non-unrated ratings for the school.
  # The return value is a hash. Counts can be extracted by typing:
  # return_value["Rating"]  Possible values return
  def count_ratings
    return_value = { H: 0, P: 0, N: 0, U: 0 }
    school_section_ids = Section.where(school_year_id: self.school_year_id).pluck(:id)
    school_section_outcome_ids = SectionOutcome.where(section_id: school_section_ids, active: true)
    section_outcome_ratings = SectionOutcomeRating.joins(:section_outcome => :section).where(section_outcome_id: school_section_outcome_ids)
    section_outcome_ratings.each do |section_outcome_rating|
      rating = section_outcome_rating.rating
      unless rating.nil? && rating.length > 0 # make sure we have a value
        # make sure we only use the first character, just in case
        return_value[rating[0].to_sym] += 1 if ['H','P','N','U'].include?(rating[0])
      end
    end
    return_value
  end

  # one time setting of model_lo_id in subject outcomes for school year rollover.
  # used so school subject outcome points to the corresponding model school lo for updating at new year
  def preset_model_lo_id
    ms = School.find(1)
    if (ms.present? && ms.acronym == 'MOD')
      # we have a model school, do the preset

      # get subject id in model school
      mod_subjs = Subject.where(school_id: ms.id)
      mod_subj_ids = mod_subjs.pluck(:id)

      # get subjects in this school by name
      sch_subjs_by_name = Hash.new
      Subject.where(school_id: self.id).each do |subj|
        sch_subjs_by_name[subj.name] = subj
      end

      # loop through model school subject outcomes and update corresponding school subject outcome if exists and not set yet
      SubjectOutcome.where(subject_id: mod_subj_ids).each do |mod_lo|
        sch_los = SubjectOutcome.where(subject_id: sch_subjs_by_name[mod_lo.subject.name], description: mod_lo.description)
        # if dup descriptions, update all
        sch_los.each do |sch_lo|
          if sch_lo.model_lo_id.blank?
            sch_lo.model_lo_id = mod_lo.id
            sch_lo.save
          end
        end
      end # loop through model school LOs
    end # if model school exists


  end


end
