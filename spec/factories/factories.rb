# All the Factories are small units of usable code. Each is setup with the minimum set of values
# required by the Model.
#
# 1) Basic Usage: Create a factory foo that accepts string variable bar
# factory :foo do
#    bar "1"
# end
#
# 2) Cascading Reference
# factory :bar
#    name "Joe"
# end
#
# factory :foo do
#    bar  #Factory foo will automatically call create :bar
# end
#
# 3) Compute a value at run time
# factory :foo
#    date { 1.day.ago }  # will always be 1 day ago from run time
# end
#
# 4) Use the same method for executing arbitrary code as the value
# factory :foo
#   cash { 200 * 50 }
# end
#
# 5) Use the same method for referencing a local variable.
# factory :teaching_assignment do
#   section
#   teacher   { FactoryGirl.create(:teacher, school: section.school) }
# end
# The pattern in 5) is used extensively. The :teaching_assignment model does not enforce any
# restriction on the teacher. But we want to setup sensible defaults. If we did not add the lambda code
# teacher will be created in a different school than the section. The code will work but it will be hardly useful.
#
# 6) Traits allow you to group attributes together and then apply them to any factory.
# trait :user_common_attributes do
#      gender                  "F"
#      first_name              { Faker::Name.first_name }
#  end
#  factory :student do
#    user_common_attributes
#  end
#
# 7) Sequence ensures we have unique values. Whenever a Model field needs to be unique, use Sequence instead of Faker.
#    This is because Faker elements are Pseudo Random and will collide once you have many elements in your test db.
#    Sequence ensures uniqueness.
#
#  # assume validation specifies that email must be unique
#  factory :user
#    sequence(:email)        { |n| "user#{n}@example.com" }
#  end
#  We could have used Faker to generate the email, but it will eventually collide, so we use sequence
#
# Usage Guide:
#    Pattern 1:
#    Call the factory closest to the model that you actually need. This will create ALL the dependencies up to School.
#    Then work your way up by referencing any variables you need. This results in the least amount of code
#
#    Pattern 2 (not reccomended):
#    Start from the top model (which is school in our case) then pass this into all the models you need.
#    This results in the most lines of code
#
#    Pattern 3:
#    Section is a central model for many tests. If you need to build a class room, start with section, then get a school
#    from the section. Then pass the school to your teacher, and student. Dont forget to create teaching_assignment and enrollment
#
#    Pattern 4 (not reccomened):
#    If you want to build a class romm, you could start with a school. You will need to get the school_year and pass it to the section
#    during it's creation. You could then pass the school to the teacher and student.
#
#    Build or Create: You can call :build or :create on all models, except noted on the factory. You could run into referential integrity
#    issues when using build, if the model expects a referenced model to have an id. Use create most of the time if you want to be happy.

FactoryGirl.define do
  #traits are reusable
  trait :user_common_attributes do
      gender                  "F"
      first_name              { Faker::Name.first_name }
      last_name               { Faker::Name.last_name }
      password                "password"
      password_confirmation   "password"
      active                  true
      sequence(:username)     { |n| "user#{n}" }
      sequence(:email)        { |n| "user#{n}@example.com" }
  end

  trait :school_common_attributes do
    sequence(:name)         { |n| "Factory School #{n}" }
    sequence(:acronym)      { |n| "SCH#{n}"}
    marking_periods         4
    street_address          { Faker::Address.street_address }
    city                    { Faker::Address.city }
    state                   { Faker::Address.state }
    zip_code                { Faker::Address.zip }
  end

  # After creation of the school, a school year will be created and assigned.
  # This will cover most use cases in Tracker.
  # If you don't want a school_year set, call :school_without_schoolyear.
  # If you call foo = build :school, you will get a school with the common attributes.
  # foo will not get a school year, but if you call save on foo, the school_year will
  # be created. after(:create) is a call back.
  factory :school do
    school_common_attributes
    #automagically set the school year for this school
    after(:create) do |school|
      school_year = FactoryGirl.create(:school_year, school: school)
      school.current_school_year=school_year
      school.save
    end
    trait :arabic do
      flags   'use_family_name,user_by_first_last,grade_in_subject_name,username_from_email'
    end
  end

  factory :school_current_year, class: School do
    school_common_attributes
    #automagically set the school year for this school
    after(:create) do |school|
      @prior_school_year = FactoryGirl.create(:prior_school_year, school: school)
      school_year = @current_school_year = FactoryGirl.create(:current_school_year, school: school)
      school.current_school_year=school_year
      school.save
    end
    trait :arabic do
      flags   'use_family_name,user_by_first_last,grade_in_subject_name,username_from_email'
    end
  end

  factory :school_prior_year, class: School do
    school_common_attributes
    #automagically set the school year for this school
    after(:create) do |school|
      prior_school_year = @prior_school_year = FactoryGirl.create(:prior_school_year, school: school)
      @current_school_year = FactoryGirl.create(:current_school_year, school: school)
      school.current_school_year=prior_school_year
      school.save
    end
    trait :arabic do
      flags   'use_family_name,user_by_first_last,grade_in_subject_name,username_from_email'
    end
  end

  #for the rare case where you want a school without a school year
  factory :school_without_schoolyear, class: School do
    school_common_attributes
  end

  factory :school_year do
    name                    "2013-2014"
    starts_at               { 80.days.ago }
    ends_at                 { 30.days.from_now }
  end

  factory :current_school_year, class: SchoolYear do
    starts_at               { Date.new(Time.now.year,9,1) }
    ends_at                 { Date.new(Time.now.year+1,6,30) }
    name                    {"#{starts_at.year}-#{ends_at.year}"}
  end

  factory :prior_school_year, class: SchoolYear do
    # name                    "2012-2013"
    starts_at               { Date.new(Time.now.year-1,9,1) }
    ends_at                 { Date.new(Time.now.year,6,30) }
    name                    {"#{starts_at.year}-#{ends_at.year}"}
  end

  factory :user do
    user_common_attributes
  end

  # NOTE: Basic student, not enrolled in a class!
  # Enroll the student before use.
  factory :student do
    user_common_attributes
    school
    grade_level  2
    student      true
  end

  factory :student_no_email, class: User do
    school
    gender "F"
    password "password"
    password_confirmation "password"
    active true
    username 'student_no_email'
    grade_level 2
    student true
    subscription_status "0"
    after(:create) do |student|
      @parent_no_email = FactoryGirl.create(:user, school_id: student.school_id, parent: true, child_id: student.id)
    end

  end

  # NOTE: Basic Teacher, not assigned to a section!
  # If going to a section, create a teaching_assignment first
  factory :teacher do
    user_common_attributes
    school
    teacher true
  end

  factory :counselor do
    user_common_attributes
    school
    counselor true
  end

  factory :researcher, class: User do
    user_common_attributes
    researcher true
  end

  factory :school_administrator do
    user_common_attributes
    school
    school_administrator true
  end

  factory :system_administrator do
    user_common_attributes
    system_administrator true
  end

  factory :discipline do
     sequence(:name) { |n| "Discipline #{n}" }
  end

  factory :teaching_assignment do
    section
    teacher   { FactoryGirl.create(:teacher, school: section.school) }
    write_access  true
  end

  factory :subject do
    sequence(:name) { |n| "Subject #{n}" }
    discipline
    association :subject_manager, factory: :teacher
    school   { subject_manager.school } #by default set the school to the same as our subject manager's school
  end

  factory :section do
    sequence(:line_number) { |n| "CLASS #{n}" }
    subject
    school_year { subject.school.current_school_year }
    message   Faker::Lorem.words(1).first
  end

  factory :enrollment do
    section
    student   { FactoryGirl.create(:student, school: section.school) }
    student_grade_level { student.grade_level }
  end

  factory :subject_outcome do
    subject
    sequence(:name) { |n| "Subject Outcome #{n}" }
    trait :arabic do
      sequence(:lo_code)        { |n| "#{subject[0...1].upcase}.#{subject.grade_from_subject_name}.#{n}"}
      sequence(:description)    { |n| "Learning Outcome #{n}"}
      marking_period            1
    end
  end

  factory :section_outcome do
    section
    subject_outcome   { FactoryGirl.create(:subject_outcome, subject: section.subject) }
    marking_period    3
    active            true
    minimized         false
  end

  factory :section_outcome_rating do
    rating            "H"
    section_outcome
    student           { FactoryGirl.create(:student, school: section_outcome.subject_outcome.subject.school) }
  end

  factory :evidence_type do
    sequence(:name) { |n| "Quiz #{n}" }
  end

  factory :evidence do
    section
    sequence(:name) { |n| "Test Evidence #{n}" }
    assignment_date { Date.today }
    active          true
    evidence_type
  end

  factory :evidence_section_outcome do
    evidence
    section_outcome
  end

  factory :evidence_section_outcome_rating do
    rating "Y"
    evidence_section_outcome
    student { FactoryGirl.create(:student, school: evidence_section_outcome.section_outcome.subject_outcome.subject.school) }
  end

  factory :evidence_hyperlink do
    evidence
    sequence(:title) { |n| "Hyperlink Title #{n}" }
    hyperlink       Faker::Internet.url
  end

  factory :evidence_attachment do
   evidence
   sequence(:name) { |n| "Attachment Name #{n}" }
   attachment      File.new(Rails.root + 'spec/fixtures/rails.png')
  end

  factory :excuse do
   sequence(:code) { |n| "EXCUS #{n}" }
   sequence(:description) { |n| "Dog ate #{n}" }
   school
  end

  factory :attendance_type do
   sequence(:description) { |n| "Tardy #{n}" }
   school
   active true
  end

  factory :attendance do
    section
    school            { section.school }
    student
    attendance_type   { FactoryGirl.create(:attendance_type, school: section.school) }
    attendance_date   { Date.today }
    excuse            { FactoryGirl.create(:excuse, school: section.school) }
    sequence(:comment) { |n| "Comment #{n}" }
  end

  factory :announcement do
    sequence(:content) { |n| "Announcement Content #{n} "}
    start_at           { 1.year.ago }
    end_at             { 1.year.from_now }
  end

  # This model cannot be saved, so call build only when using it, not create
  factory :report_card_request do
    grade_level 5
  end

  factory :server_config do
    # support_team        "Tracker Support Team"
    # school_support_team "School IT Support Team"
    # server_name         "Tracker System"
    # web_server_name     "PARLO Tracker Web Server"
  end
end
