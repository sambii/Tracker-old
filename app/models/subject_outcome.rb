# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class SubjectOutcome < ActiveRecord::Base
  # Access Control
  # using_access_control

  # Relationships
  belongs_to              :subject
  has_many                :section_outcomes, :dependent => :destroy
  has_many                :section_outcome_ratings, :through => :section_outcomes

  # Validations
  validates_presence_of   :subject_id
  # validates_uniqueness_of :name, :scope => :subject_id
  validate :unique_lo_code_per_subject

  def unique_lo_code_per_subject
    matches = SubjectOutcome.where(subject_id: self.subject_id, lo_code: self.lo_code, description: self.description)
    if (matches.length == 1 && matches.first.id != self.id) || matches.length > 1
      errors.add(:name, "Learning Outcome Code and Description are not unique for this Subject")
    end

  end

  # Other Definitions

  def shortened_name
    # n = name
    # if n.length > 50
    #   n = name[0..49] + "..."
    # end
    # return n
    read_attribute(:name).truncate(50, omission: '...')
  end

  def shortened_description
    # n = description
    # if n.length > 50
    #   n = description[0..49] + "..."
    # end
    # return n
    read_attribute(:description).truncate(50, omission: '...')
  end

  # getter for original name field (combination of new lo_code and description fields).
  def name
    if self.lo_code.present?
     "#{self.lo_code} - #{self.description}"
    else
      self.description
    end
  end

  # setter for original name field (combination of new lo_code and description fields).
  def name=(name_in)
    split_name = name_in.strip().split(' - ')
    if split_name.length == 1
      self.lo_code = ''
      self.description = split_name[0]
    elsif split_name.length == 2
      self.lo_code = split_name[0]
      self.description = split_name[1]
    elsif split_name.length > 2
      self.lo_code = split_name[0]
      self.description = split_name[1]
      split_name.drop(2).each do |str|
        self.description << ' - '+str
      end
    else
      self.errors.add(:name, 'is required.')
    end
  end

  # marking period bitmask setter function
  # e.g bitmask 13 (1101) == bitmask string '1&3&4'
  def marking_period=(mask)
    if mask.is_a? Integer
      write_attribute(:marking_period, mask)
    elsif mask.is_a? String
      masko = SubjectOutcome.get_bitmask(mask)
      write_attribute(:marking_period, masko)
    else
      self.errors.add(:marking_period, 'Invalid Marking Period Mask')
    end
  end

  # marking_period (as bitmask string) getter
  # e.g bitmask 13 (1101) == bitmask string '1&3&4'
  def marking_period_string
    return SubjectOutcome.get_bitmask_string(read_attribute(:marking_period))
  end

  # marking_period getter
  # e.g bitmask 13 (1101) == bitmask string '1&3&4'
  def marking_period
    return read_attribute(:marking_period)
  end

  # unreliable way to get grade from learning outcome. get it from subject name
  # use: Subject.grade_from_subject_name.
  # e.g. lo.subject.grade_from_subject_name
  # def grade_from_lo_code
  #   parts = read_attribute(:lo_code).split(/\W/)
  #   return (parts.length == 3) ? parts[1] : ' '
  # end

  # class level helper functions

  # convert marking period bitmask to a string with set marking periods with & separator
  # e.g bitmask 13 (1101) == bitmask string '1&3&4'
  def self.get_bitmask(bitmask_string)
    mask = 0
    mps = (bitmask_string ||= '').split('&')
    mps.each do |mp|
      if /^[0-9]+$/.match(mp).present?
        mask += 2 ** ((mp.to_i)-1)
      end
    end
    return mask
  end

  # convert marking period bitmask to a string with set marking periods with & separator
  # e.g bitmask 13 (1101) == bitmask string '1&3&4'
  def self.get_bitmask_string(bitmask)
    str_array = []
    bm = bitmask.is_a?(Integer) ? bitmask : 0
    bm.to_s(2).reverse.split(//).each_with_index{ |x, i| str_array << i+1 if x == '1' }
    return str_array.join('&')
  end

end
