namespace :seed_school do
  desc "Create training data"

  # BUSINESS LOGIC
  # 30 Generic Teacher Accounts for each school (Teacher 1, Teacher 2, Teacher 3, etc.)
  # Each teacher should have two sections (Section 1, Section 2)
  # Each sections should have at 15 students (Last Name, First Name)
  # Each section should have at least 10 learning outcomes
  # 5 of learning outcomes should already be added to the section
    #   Each of the 5 LOs should have 4 pieces of evidence
    #     Of the five,  Two of the LOs and the supporting evidence should be rated 
    #         Of the five,  the remaining Three of the LOs should NOT be rated 
    #             Of the three not rated LOs, Two of the LOs supporting evidence should be rated
    #                 Of the three not rated LOs, the one remaining LOs supporting evidence should NOT be rated
 

    #PRE-REQ: An Evidence Type named "Homework" must exist in the system else this script will fail
  task create: :environment do

    puts "create schools, school year and admins"


    # This creates a Seed school with basic information for a school

    school = School.create!(
      name: Faker::Company.name + " Seed School",
      acronym: Faker::Lorem.characters(4).upcase,
      street_address: "1 Stub Lane",
      city: "Conshohocken",
      state: "PA",
      zip_code: "19428",
      marking_periods: 4,
    )
     
    school_year = SchoolYear.create!(
      name: "2012, 2013",
      school_id: school.id,
      starts_at: Date.parse("2012-09-01"),
      ends_at: Date.parse("2013-06-20")
    ) 

    school.school_year_id = school_year.id
    school.save!

    sa = SchoolAdministrator.new(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.safe_email,
      password: "password",
      password_confirmation: "password"
    )
    sa.username = "school#{school.id}admin"
    sa.school_id = school.id
    sa.save

    c = Counselor.new(
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        email: Faker::Internet.safe_email,
        password: "password",
        password_confirmation: "password"
    )
    c.username = "school#{school.id}counselor"
    c.school_id = school.id
    c.save

    teacher = Teacher.new(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      email: Faker::Internet.safe_email,
      password: "password",
      password_confirmation: "password"
    )
    teacher.username = "school#{school.id}teacher"
    teacher.school_id = school.id
    teacher.save

    students = []
    25.times do |n|
      s = Student.new(
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        email: Faker::Internet.safe_email,
        grade_level: 9,
        gender: "F",
        password: "password",
        password_confirmation: "password"
        )
      s.username = "school#{school.id}student#{n}"
      s.school_id = school.id
      s.save
      students << s
    end


    discipline = Discipline.create!(
      name: "Discipline #{school.id}" 
    )
     
    subject = Subject.create!(
      name: "Subject #{school.id}",
      discipline_id: discipline.id,
      school_id: school.id,
      subject_manager_id: teacher.id
    )
     

    section = Section.create!(
      line_number: "Class #{school.id}",
      subject_id: subject.id,
      school_year_id: school.school_year_id,
      message: "Listen here!"
    )
     
    students.each do |student|
      Enrollment.create!(
        student_id: student.id,
        section_id: section.id,
        student_grade_level: student.grade_level
      )
    end

    TeachingAssignment.create!(
      teacher_id: teacher.id,
      section_id: section.id
    )
    subject_outcomes=[]
    10.times do |n|
      s = SubjectOutcome.create!(
        name: "Learning Outcome #{school.id}_#{n}",
        subject_id: subject.id,
        essential: true
      )
      subject_outcomes << s
    end

    subject_outcome = SubjectOutcome.last

    section_outcomes=[]
    subject_outcomes.each do |subject_outcome|
      s = SectionOutcome.new
      s.subject_outcome_id = subject_outcome.id
      s.section_id = section.id
      s.marking_period = Random.rand(4) # Bitmask!
      s.active = true
      s.minimized = false
      s.save
      section_outcomes << s
    end

    evidence_types=[]
    8.times do |n|
      # if 'Quiz nn' exists already, use it, else create it
      db_evidence_types = EvidenceType.where(name: "Quiz #{n}")
      if db_evidence_types.count > 0
        evidence_types << db_evidence_types.first
      else
        e = EvidenceType.create!(name: "Quiz #{n}")
        evidence_types << e
      end
    end

    evidences=[]
    evidence_types.each do |evidence_type|
      e = Evidence.create!(
        section_id: section.id,
        name: "Sample Evidence #{school.id}_#{ evidence_types.index(evidence_type) }",
        description: "Basically, evidences are homework assignments, tests, quizzes, etc.",
        assignment_date: DateTime.now,
        active: true,
        evidence_type_id: evidence_type.id,
        reassessment: false
      )
      evidences << e
    end

    evidence_section_outcomes=[]
    section_outcomes.each do |section_outcome|
      evidences.each do |evidence| 
       evidence_section_outcomes << EvidenceSectionOutcome.create!(
          evidence_id: evidence.id,
          section_outcome_id: section_outcome.id
        )
      end
    end

    # e_ratings = ["R","G","Y","U"]
    # #change this if we create multple schools / sections
    # evidence_section_outcomes.each  do |eso|
    #   students.each do |student|
    #     EvidenceSectionOutcomeRating.create!(
    #       rating: e_ratings[Random.rand(4)],
    #       student_id: student.id,
    #       evidence_section_outcome_id: eso.id,
    #       comment: ""
    #     )
    #   end
    # end

    # so_ratings = ["N","P","H","U"]
    # section_outcomes.each do |section_outcome|
    #   students.each do |student|
    #     SectionOutcomeRating.create!(
    #       rating: so_ratings[Random.rand(4)],
    #       student_id: student.id,
    #       section_outcome_id: section_outcome.id
    #       )
    #   end
    # end
    puts "Done"
  end
end