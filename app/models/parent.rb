# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
class Parent < User
  default_scope where(parent: true, active: true)
  # Access Control
  # using_access_control

  # Callbacks

  # Relationships
  belongs_to :child, class_name: Student

  # Validations

  # Other Methods
  def self.send_emails subscription_status
    status = subscription_status.to_s
    Parent.where(subscription_status: status).each do |parent|
      if parent.email.present? && parent.active
        if parent.child.active
          parent.child.cur_yr_active_enrollments.current.active_enrollment.each do |e|
            StudentMailer.show(parent.email, parent.child.id, e.section.id).deliver
            File.open("log/email.log","a") do |f|
              f.puts "#{Time.now}: Sent #{subscription_status} email to Parent - #{parent.email}."
            end
          end
        end
      end
    end
  end

  def full_name
    if self.student.nil?
      student = Student.find(self.child_id)
      student.full_name + "'s Parent/Guardian"
    else
     self.student.full_name + "'s Parent/Guardian"
    end
  end

  def subscription_status
    orig = read_attribute(:'subscription_status')
    if orig.nil? || orig == '0'
      'Never'
    else
      orig
    end
  end

  # Overrides user#set_unique_username
  def set_unique_username
    self.username  = (child.username + "_p").downcase
    i         = 2
    # until unique_username?
    until is_unique_username
      self.username = (child.username + "_p#{i}").downcase
      i += 1
    end
    true
  end
end
