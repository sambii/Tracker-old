# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class User < ActiveRecord::Base

  attr_accessible :duty_par, :permission_par, :xid, :first_name, :last_name, :email, :street_address, :city, :state, :zip_code, :active, :grade_level, :gender, :race, :special_ed, :child_id, :password, :password_confirmation, :subscription_status

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable and :omniauthable
  devise :database_authenticatable, #:registerable,             # (removed because accounts are created automagically
                                                                #  when students and teachers are created)
    :timeoutable, # to turn on session timeouts

         :rememberable, :trackable, :recoverable#, :validatable # (removed in favor of custom validations
                                                                # because :validatable requires an email address)
  scope :alphabetical, order([:last_name, :first_name])

  # Validations

  validates_presence_of     :password, if: :password_required?
  validates_confirmation_of :password, if: :password_required?
  validates_length_of       :password, within: 6..128, if: :password_required?
  validates_inclusion_of    :race, in: RACES, allow_blank: true
  validates_presence_of     :first_name, :last_name, if: :role_requires_name?
  validates_presence_of     :username
  validates_uniqueness_of   :username
  validates                 :email, format: { with: /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i }, allow_blank: true
  validates_uniqueness_of   :xid,
                            scope: :school_id,
                            allow_blank: true
  validate                  :role_required
  # validate                  :valid_arabic

  scope :in_race, lambda { |races| where(race: races) }


  # Roles
  # ordered into most powerful first
  def role_symbols
    roles = []
    roles << :system_administrator if system_administrator?
    roles << :researcher if researcher?
    roles << :school_administrator if school_administrator?
    roles << :teacher if teacher?
    roles << :counselor if counselor?
    roles << :parent if parent?
    roles << :student if student?
    roles
  end

  def self.role_symbol_to_name(role_sym)
    case role_sym.to_sym
    when :system_administrator
      return 'Sys Admin'
    when :researcher
      return 'Researcher'
    when :school_administrator
      return 'School Admin'
    when :teacher
      return 'Teacher'
    when :counselor
      return 'Counselor'
    when :parent
      return 'Parent'
    when :student
      return 'Student'
    end
  end

  # Permissions
  # List of valid permissions are in here!
  def valid_permission?(perm)
    ['manage_subject_admin', 'subject_admin'].include?(perm.to_s)
  end

  def has_permission?(perm)
    (self.permissions || '').split(',').include?(perm.to_s)
  end

  def add_permission(perm)
    # Note: does not save
    perms = (self.permissions || '').split(',')
    if self.valid_permission?(perm) && !perms.include?(perm.to_s)
      self.permissions = (perms << perm.to_s).join(',')
      return true
    else
      return false
    end
  end

  def remove_permission(perm)
    # Note: does not save
    perms = (self.permissions || '').split(',')
    if perms.include?(perm.to_s)
      self.permissions = (perms - ([] << perm.to_s)).join(',')
      return true
    else
      return false
    end
  end

  def permission_par=(par)
    par.each do |p,v|
      if ['on', 'true'].include?(v.to_s)
        add_permission(p)
      elsif ['off', 'false'].include?(v.to_s)
        remove_permission(p)
      else
        Rails.logger.error('ERROR: Invalid permission #{p} -> #{v}')
      end
    end
    Rails.logger.debug("*** self.permissions: #{self.permissions}")
  end


  # Duties
  # List of valid duties are in here!
  def valid_duty?(duty)
    [].include?(duty.to_s)
  end

  def has_duty?(duty)
    (self.duties || '').split(',').include?(duty.to_s)
  end

  def add_duty(duty)
    # Note: does not save
    duty_a = (self.duties || '').split(',')
    if self.valid_duty?(duty) && !duty_a.include?(duty.to_s)
      self.duties = (duty_a << duty.to_s).join(',')
      return true
    else
      return false
    end
  end

  def remove_duty(duty)
    # Note: does not save
    duty_a = (self.duties || '').split(',')
    if duty_a.include?(duty.to_s)
      self.duties = (duty_a - ([] << duty.to_s)).join(',')
      return true
    else
      return false
    end
  end

  def duty_par=(par)
    par.each do |p,v|
      if ['on', 'true'].include?(v.to_s)
        add_duty(p)
      elsif ['off', 'false'].include?(v.to_s)
        remove_duty(p)
      else
        Rails.logger.error('ERROR: Invalid duty #{p} -> #{v}')
      end
    end
  end



  def staff?
    (teacher? || counselor? || school_administrator? || system_administrator? || researcher?) ? true : false
  end

  def see_school?
    (teacher? || counselor? || school_administrator? || system_administrator? || researcher?) ? true : false
  end

  def see_all_school?
    (school_administrator? || system_administrator? || researcher?) ? true : false
  end

  def see_all?
    (system_administrator? || researcher?) ? true : false
  end

  # Other Definitions

  def f_last_name
    ( (self.first_name.present? ? self.first_name[0] : '') + self.last_name).downcase
  end

  def full_name
    self.first_name.to_s + " " + self.last_name.to_s
  end

  def last_name_first
    self.last_name + ", " + self.first_name
  end

  # New UI - allow student listing expand/collapse break by first initial of last name
  def last_name_initial
    self.last_name.length > 0 ? self.last_name[0] : ''
  end

  # New UI - allow student listing expand/collapse break by first initial of last name
  def first_name_initial
    self.first_name.length > 0 ? self.first_name[0] : ''
  end

  def set_temporary_password
    temporary_string = SecureRandom.hex(5)
    self.password               = temporary_string
    self.password_confirmation  = temporary_string
    self.temporary_password     = temporary_string
  end

  # Because usernames are generated automatically for school personnel, students, and parents,
  # this method is called to determine whether the generated username is in fact unique. The controllers
  # for those personnel types are responsible for handling the result of this method.
  def unique_username?
    users = User.all
    usernames = users.collect{|u| u.username}
    if new_record?
      !(usernames.include? username) && !(username.nil?)
    else
      usernames.count(username) == 1 or usernames.count(username) == 0
    end
  end

  # def arabic_name?
  #   self.last_name =~ /[\u0600-\u06ff]|[\u0750-\u077f]|[\ufb50-\ufc3f]|[\ufe70-\ufefc]/
  # end

  def set_unique_username
    school ||= School.find self.school_id

    # if last name has arabic, set the username to email (prior to @)
    self.username  = (school.acronym + "_" + f_last_name).downcase
    i         = 2
    until unique_username?
      self.username = (school.acronym + '_' + f_last_name + i.to_s).downcase
      i += 1
    end
    Rails.logger.debug("*** regular username: #{self.username}")
    true

  end

  # Returns nil if no counselor is found.
  # Counselor.find(id) returned an exception if none was found...
  def counselor
    Counselor.where(id: id).first
  end

  # Returns nil if no teacher is found.
  # Teacher.find(id) returned an exception if none was found...
  def school_administrator
    SchoolAdministrator.where(id: id).first
  end

  # Returns nil if no teacher is found.
  # Teacher.find(id) returned an exception if none was found...
  def teacher
    Teacher.where(id: id).first
  end

  def can_change_school?
    system_administrator? || researcher?
  end

  # New UI
  # Staff Listing number of assignments column
  def current_assignments
    if school_id.nil?
      return []
    else
      sy_id = School.find(school_id).school_year_id
      tas = TeachingAssignment.where(teacher_id: id).pluck(:section_id)
      Section.where(school_year_id: sy_id, id: tas)
    end
  end

  protected
    def role_requires_name?
      ([:system_administrator, :parent]).each do |role|
        return false if self[role] == true
      end
      # allow no first name if last name has arabic characters
      true
    end

    def role_required
      ROLES.each do |role|
        return if self[role] == true
      end
      self.errors.add(:base, "You must select at least one role!")
    end

    def password_required?
      !persisted? || !password.nil? || !password_confirmation.nil?
    end

    def subject_manager?
        if teacher.respond_to?(:managed_subjects)
          return true if teacher.managed_subjects.size > 0
        end
        false
    end

    # def valid_arabic
    #   errors.add(:email, "email is required for Arabic") if (self.arabic_name? && self.email.blank?)
    # end
end
