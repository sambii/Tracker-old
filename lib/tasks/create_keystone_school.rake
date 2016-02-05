namespace :keystone_school do
  desc "Create demo data with keystone assessment anchors as Learning Outcomes."

  task create: :environment do

    ###########################################################
    # check to make sure school doesn't already exist
    sch_test = School.where(name: "Keystone High School")
    if sch_test.count > 0
      puts "***** School already exists *****"
      break
    end


    ###########################################################
    # create our evidence types if not there already

    ets=["In Class", "Homework", "Quiz", "Test"]
    et_levels = ['R', 'BA', 'ST', 'ST']
    evidence_types = []
    ets.each do |et|
      db_et = EvidenceType.where(name: et)
      if db_et.count > 0
        evidence_types << db_et.first
      else
        e = EvidenceType.create(name: et)
        evidence_types << e
      end
    end


    db_disc = Discipline.where(name: "English")
    if db_disc.count > 0
      english = db_disc.first
    else
      english = Discipline.create(name: "English")
    end
     
    db_disc = Discipline.where(name: "Mathematics")
    if db_disc.count > 0
      mathematics = db_disc.first
    else
      mathematics = Discipline.create(name: "Mathematics")
    end     
     
    db_disc = Discipline.where(name: "Biology")
    if db_disc.count > 0
      biology = db_disc.first
    else
      biology = Discipline.create(name: "Biology")
    end
     
     
    puts "create schools, school year and users"

    # This creates a Seed school with basic information for a school

    school = School.create(
      name: "Keystone High School",
      acronym: "KHS",
      street_address: "101 W. Elm St.",
      city: "Conshohocken",
      state: "PA",
      zip_code: "19428",
      marking_periods: 4,
    )
     
    school_year = SchoolYear.create(
      name: "2015-16",
      school_id: school.id,
      starts_at: Date.parse("2015-09-01"),
      ends_at: Date.parse("2016-06-21")
    ) 

    school.update_attributes(school_year_id:school_year.id)


    ###########################################################
    # create the users

    SchoolAdministrator.create(
      username: "khs_admin",
      first_name: "Khs",
      last_name: "Admin",
      email: "ddaugherty@21pstem.org",
      school_id: school.id,
      password: "password",
      password_confirmation: "password"
    )

    Counselor.create(
        username: "khs_counselor",
        first_name: "Khs",
        last_name: "Counselor",
        email: "ddaugherty@21pstem.org",
        school_id: school.id,
        password: "password",
        password_confirmation: "password"
    )

    english_teacher = Teacher.create(
      username: "khs_english_teacher",
      first_name: "Khs_english",
      last_name: "Teacher",
      email: "ddaugherty@21pstem.org",
      school_id: school.id,
      password: "password",
      password_confirmation: "password"
    )
     
    biology_teacher = Teacher.create(
      username: "khs_biology_teacher",
      first_name: "Khs_biology",
      last_name: "Teacher",
      email: "ddaugherty@21pstem.org",
      school_id: school.id,
      password: "password",
      password_confirmation: "password"
    )
     
    algebra_teacher = Teacher.create(
      username: "khs_algebra_teacher",
      first_name: "Khs_algebra",
      last_name: "Teacher",
      email: "ddaugherty@21pstem.org",
      school_id: school.id,
      password: "password",
      password_confirmation: "password"
    )
     
    students = []
    45.times do |n|
      s = Student.create(
        username: "khs_student#{n}",
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        email: Faker::Internet.safe_email,
        grade_level: 9,
        gender: "F",
        school_id: school.id,
        password: "password",
        password_confirmation: "password"
        )
      students << s
    end

    ###########################################################
    # create the courses and enroll students and assign the teacher.

    puts ("Create Subjects and Sections")

    # English
    puts ("Create  Subjects and Sections for English")

    english_lit_9 = Subject.create(
      name: "9th Grade English Lit.",
      discipline_id: english.id,
      school_id: school.id,
      subject_manager_id: english_teacher.id
    )

    puts ("school: #{school.inspect}")
    puts ("school_year: #{school_year.inspect}")
    puts ("english_lit_9: #{english_lit_9.inspect}")

    english_lit_9_1 = Section.create(
      line_number: "Section 1",
      subject_id: english_lit_9.id,
      school_year_id: school_year.id,
      message: "Homework Due Thursday!!"
    )
    TeachingAssignment.create(
      teacher_id: english_teacher.id,
      section_id: english_lit_9_1.id
    )
    students[0..14].each do |student|
      Enrollment.create(
        student_id: student.id,
        section_id: english_lit_9_1.id,
        student_grade_level: student.grade_level
      )
    end
     
    english_lit_9_2 = Section.create(
      line_number: "Section 2",
      subject_id: english_lit_9.id,
      school_year_id: school_year.id,
      message: "Homework Due Thursday, Quiz on Friday !!!!"
    )
    TeachingAssignment.create(
      teacher_id: english_teacher.id,
      section_id: english_lit_9_2.id
    )
    students[15..29].each do |student|
      Enrollment.create(
        student_id: student.id,
        section_id: english_lit_9_2.id,
        student_grade_level: student.grade_level
      )
    end
     
    english_lit_9_3 = Section.create(
      line_number: "Section 3",
      subject_id: english_lit_9.id,
      school_year_id: school_year.id,
      message: "Have a great vacation !"
    )
    TeachingAssignment.create(
      teacher_id: english_teacher.id,
      section_id: english_lit_9_3.id
    )
    students[30..44].each do |student|
      Enrollment.create(
        student_id: student.id,
        section_id: english_lit_9_3.id,
        student_grade_level: student.grade_level
      )
    end
     

    # Biology
    puts ("Create Subjects and Sections for Biology")
     
    biology_10 = Subject.create(
      name: "9th Grade Biology",
      discipline_id: biology.id,
      school_id: school.id,
      subject_manager_id: biology_teacher.id
    )
     
    biology_10_1 = Section.create(
      line_number: "Section 1",
      subject_id: biology_10.id,
      school_year_id: school_year.id,
      message: "Homework Due Monday!!"
    )
    TeachingAssignment.create(
      teacher_id: biology_teacher.id,
      section_id: biology_10_1.id
    )
    students[0..14].each do |student|
      Enrollment.create(
        student_id: student.id,
        section_id: biology_10_1.id,
        student_grade_level: student.grade_level
      )
    end
     
    biology_10_2 = Section.create(
      line_number: "Section 2",
      subject_id: biology_10.id,
      school_year_id: school_year.id,
      message: "Homework Due Monday, Exam on Friday !!!!"
    )
    TeachingAssignment.create(
      teacher_id: biology_teacher.id,
      section_id: biology_10_2.id
    )
    students[15..29].each do |student|
      Enrollment.create(
        student_id: student.id,
        section_id: biology_10_2.id,
        student_grade_level: student.grade_level
      )
    end
     
    biology_10_3 = Section.create(
      line_number: "Section 3",
      subject_id: biology_10.id,
      school_year_id: school_year.id,
      message: "Have a great Holiday !"
    )
    TeachingAssignment.create(
      teacher_id: biology_teacher.id,
      section_id: biology_10_3.id
    )
    students[30..44].each do |student|
      Enrollment.create(
        student_id: student.id,
        section_id: biology_10_3.id,
        student_grade_level: student.grade_level
      )
    end


 
    # Algebra
    puts ("Create Subjects and Sections for Algebra")

    algebra_I_9 = Subject.create(
      name: "Algebra I",
      discipline_id: mathematics.id,
      school_id: school.id,
      subject_manager_id: algebra_teacher.id
    )
     
    algebra_I_9_1 = Section.create(
      line_number: "Section 1",
      subject_id: algebra_I_9.id,
      school_year_id: school_year.id,
      message: "Quiz Tuesday"
    )
    TeachingAssignment.create(
      teacher_id: algebra_teacher.id,
      section_id: algebra_I_9_1.id
    )
    students[0..14].each do |student|
      Enrollment.create(
        student_id: student.id,
        section_id: algebra_I_9_1.id,
        student_grade_level: student.grade_level
      )
    end
     
    algebra_I_9_2 = Section.create(
      line_number: "Section 2",
      subject_id: algebra_I_9.id,
      school_year_id: school_year.id,
      message: "Project Due Friday !!!!"
    )
    TeachingAssignment.create(
      teacher_id: algebra_teacher.id,
      section_id: algebra_I_9_2.id
    )
    students[15..29].each do |student|
      Enrollment.create(
        student_id: student.id,
        section_id: algebra_I_9_2.id,
        student_grade_level: student.grade_level
      )
    end
     
    algebra_I_9_3 = Section.create(
      line_number: "Section 3",
      subject_id: algebra_I_9.id,
      school_year_id: school_year.id,
      message: "Have a great Weekend !"
    )
    TeachingAssignment.create(
      teacher_id: algebra_teacher.id,
      section_id: algebra_I_9_3.id
    )
    students[30..44].each do |student|
      Enrollment.create(
        student_id: student.id,
        section_id: algebra_I_9_3.id,
        student_grade_level: student.grade_level
      )
    end
 
     

    ###########################################################
    # create the Learning Outcomes using the PA Common Core Assessment Anchors
    #
    # English Literature

    puts ("Create Learning Outcomes for English")

     
    english_los=[]
    english_los << SubjectOutcome.create(
      name: "L.F.1.1 Use appropriate strategies to analyze an author's purpose and how it is achieved in literature.",
      subject_id: english_lit_9.id,
      essential: true
    )
    english_los << SubjectOutcome.create(
      name: "L.F.1.2 Use appropriate strategies to determine and clarify meaning of vocabulary in literature.",
      subject_id: english_lit_9.id,
      essential: true
    )
    english_los << SubjectOutcome.create(
      name: "L.F.1.3 Use appropriate strategies to comprehend literature during the reading process",
      subject_id: english_lit_9.id,
      essential: true
    )
    english_los << SubjectOutcome.create(
      name: "L.F.2.1 Use appropriate strategies to make and support interpretations of literature. ",
      subject_id: english_lit_9.id,
      essential: true
    )
    english_los << SubjectOutcome.create(
      name: "L.F.2.2 Use appropriate strategies to compare, analyze, and evaluate literary forms.",
      subject_id: english_lit_9.id,
      essential: true
    )
    english_los << SubjectOutcome.create(
      name: "L.F.2.3 Use appropriate strategies to compare, analyze, and evaluate literary elements.",
      subject_id: english_lit_9.id,
      essential: true
    )
    english_los << SubjectOutcome.create(
      name: "L.F.2.4 Use appropriate strategies to interpret and analyze the universal significance of literary fiction",
      subject_id: english_lit_9.id,
      essential: true
    )
    english_los << SubjectOutcome.create(
      name: "L.F.2.5 Use appropriate strategies to identify and analyze literary devices and patterns in literary fiction.",
      subject_id: english_lit_9.id,
      essential: true
    )
    english_los << SubjectOutcome.create(
      name: "L.N.1.1 Use appropriate strategies to analyze an author's purpose and how it is achieved in literature.",
      subject_id: english_lit_9.id,
      essential: true
    )
    english_los << SubjectOutcome.create(
      name: "L.N.1.2 Use appropriate strategies to determine and clarify meaning of vocabulary in literature.",
      subject_id: english_lit_9.id,
      essential: true
    )
    english_los << SubjectOutcome.create(
      name: "L.N.1.3 Use appropriate strategies to comprehend literature during the reading process",
      subject_id: english_lit_9.id,
      essential: true
    )
    english_los << SubjectOutcome.create(
      name: "L.N.2.1 Use appropriate strategies to make and support interpretations of literature. ",
      subject_id: english_lit_9.id,
      essential: true
    )
    english_los << SubjectOutcome.create(
      name: "L.N.2.2 Use appropriate strategies to compare, analyze, and evaluate literary forms.",
      subject_id: english_lit_9.id,
      essential: true
    )
    english_los << SubjectOutcome.create(
      name: "L.N.2.3 Use appropriate strategies to compare, analyze, and evaluate literary elements.",
      subject_id: english_lit_9.id,
      essential: true
    )
    english_los << SubjectOutcome.create(
      name: "L.N.2.4 Use appropriate strategies to identify and analyze text organization and structure in literary nonfiction.",
      subject_id: english_lit_9.id,
      essential: true
    )
    english_los << SubjectOutcome.create(
      name: "L.N.2.5 Use appropriate strategies to identify and analyze essential and nonessential information in literary nonfiction. ",
      subject_id: english_lit_9.id,
      essential: true
    )

    puts ("Create Subject Outcomes for English")
    english_sos=[]
    english_los.each_with_index do |subject_outcome, ix|
      # create section outcome for block 1
      english_sos << SectionOutcome.create(
        subject_outcome_id: subject_outcome.id,
        section_id: english_lit_9_1.id,
        marking_period: 2 ** (ix / 4), # Bitmask! 0->1(mp1), 1->2(mp2), 2->4(mp3), 3->8(mp4)
        active: true,
        minimized: false
      )
      # create section outcome for block 2
      english_sos << SectionOutcome.create(
        subject_outcome_id: subject_outcome.id,
        section_id: english_lit_9_2.id,
        marking_period: 2 ** (ix / 4), # Bitmask! 0->1(mp1), 1->2(mp2), 2->4(mp3), 3->8(mp4)
        active: true,
        minimized: false
      )
      # create section outcome for block 3
      english_sos << SectionOutcome.create(
        subject_outcome_id: subject_outcome.id,
        section_id: english_lit_9_3.id,
        marking_period: 2 ** (ix / 4), # Bitmask! 0->1(mp1), 1->2(mp2), 2->4(mp3), 3->8(mp4)
        active: true,
        minimized: false
      )
      break if ix >= 7    # only load the first two semesters of LOs to each section
    end


    ###########################################################
    # create the Learning Outcomes using the PA Common Core Assessment Anchors
    #
    # Biology
     
    puts ("Create Learning Outcomes for Biology")

    biology_los=[]
    biology_los << SubjectOutcome.create(
      name: "BIO.A.1.1 Explain the characteristics common to all organisms.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.A.1.2 Describe relationships between structure and function at biological levels of organization.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.A.2.1 Describe how the unique properties of water support life on Earth.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.A.2.2 Describe and interpret relationships between structure and function at various levels of biochemical organization (i.e., atoms, molecules, and macromolecules).",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.A.2.3 Explain how enzymes regulate biochemical reactions within a cell.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.A.3.1 Identify and describe the cell structures involved in processing energy.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.A.3.2 Identify and describe how organisms obtain and transform energy for their life processes.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.A.4.1 Identify and describe the cell structures involved in transport of materials into, out of, and throughout a cell.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.A.4.2 Explain mechanisms that permit organisms to maintain biological balance between their internal and external environments.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.B.1.1 Describe the three stages of the cell cycle: interphase, nuclear division, cytokinesis.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.B.1.2 Explain how genetic information is inherited.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.B.2.1 Compare Mendelian and non-Mendelian patterns of inheritance.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.B.2.2 Explain the process of protein synthesis (i.e., transcription, translation, and protein modification).",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.B.2.3 Explain how genetic information is expressed.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.B.2.4 Apply scientific thinking, processes, tools, and technologies in the study of genetics.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.B.3.1 Explain the mechanisms of evolution.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.B.3.2 Analyze the sources of evidence for biological evolution.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.B.3.3 Apply scientific thinking, processes, tools, and technologies in the study of the theory of evolution.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.B.4.1 Describe ecological levels of organization in the biosphere.",
      subject_id: biology_10.id,
      essential: true
    )
    biology_los << SubjectOutcome.create(
      name: "BIO.B.4.2 Describe interactions and relationships in an ecosystem.",
      subject_id: biology_10.id,
      essential: true
    )

    puts ("Create Subject Outcomes for Biology")

    biology_sos=[]
    biology_los.each_with_index do |subject_outcome, ix|
      # create section outcome for block 1
      biology_sos << SectionOutcome.create(
        subject_outcome_id: subject_outcome.id,
        section_id: biology_10_1.id,
        marking_period: 2 ** (ix / 4), # Bitmask! 0->1(mp1), 1->2(mp2), 2->4(mp3), 3->8(mp4)
        active: true,
        minimized: false
      )
      # create section outcome for block 2
      biology_sos << SectionOutcome.create(
        subject_outcome_id: subject_outcome.id,
        section_id: biology_10_2.id,
        marking_period: 2 ** (ix / 4), # Bitmask! 0->1(mp1), 1->2(mp2), 2->4(mp3), 3->8(mp4)
        active: true,
        minimized: false
      )
      # create section outcome for block 3
      biology_sos << SectionOutcome.create(
        subject_outcome_id: subject_outcome.id,
        section_id: biology_10_3.id,
        marking_period: 2 ** (ix / 4), # Bitmask! 0->1(mp1), 1->2(mp2), 2->4(mp3), 3->8(mp4)
        active: true,
        minimized: false
      )
      break if ix >= 7    # only load the first two semesters of LOs to each section
    end


    ###########################################################
    # create the Learning Outcomes using the PA Common Core Assessment Anchors
    #
    # Algebra I
     
    puts ("Create Learning Outcomes for Algebra")

    algebra_los=[]
    algebra_los << SubjectOutcome.create(
      name: "A1.1.1.1 Represent and/or use numbers in equivalent forms (e.g., integers, fractions, decimals, percents, square roots, and exponents).",
      subject_id: algebra_I_9.id,
      essential: true
    )
    algebra_los << SubjectOutcome.create(
      name: "A1.1.1.2 Apply number theory concepts to show relationships between real numbers in problem-solving settings.",
      subject_id: algebra_I_9.id,
      essential: true
    )
    algebra_los << SubjectOutcome.create(
      name: "A1.1.1.3 Use exponents, roots, and/or absolute values to solve problems.",
      subject_id: algebra_I_9.id,
      essential: true
    )
    algebra_los << SubjectOutcome.create(
      name: "1.1.1.4 Use estimation strategies in problem-solving situations.",
      subject_id: algebra_I_9.id,
      essential: true
    )
    algebra_los << SubjectOutcome.create(
      name: "A1.1.1.5 Simplify expressions involving polynomials.",
      subject_id: algebra_I_9.id,
      essential: true
    )
    algebra_los << SubjectOutcome.create(
      name: "A1.1.2.1 Write, solve, and/or graph linear equations using various methods.",
      subject_id: algebra_I_9.id,
      essential: true
    )
    algebra_los << SubjectOutcome.create(
      name: "A1.1.2.2 Write, solve, and/or graph systems of linear equations using various methods.",
      subject_id: algebra_I_9.id,
      essential: true
    )
    algebra_los << SubjectOutcome.create(
      name: "A1.1.3.1 Write, solve, and/or graph linear inequalities using various methods.",
      subject_id: algebra_I_9.id,
      essential: true
    )
    algebra_los << SubjectOutcome.create(
      name: "A1.1.3.2 Write, solve, and/or graph systems of linear inequalities using various methods.",
      subject_id: algebra_I_9.id,
      essential: true
    )
    algebra_los << SubjectOutcome.create(
      name: "A1.2.1.1 Analyze and/or use patterns or relations.",
      subject_id: algebra_I_9.id,
      essential: true
    )
    algebra_los << SubjectOutcome.create(
      name: "A1.2.1.2 Interpret and/or use linear functions and their equations, graphs, or tables.",
      subject_id: algebra_I_9.id,
      essential: true
    )
    algebra_los << SubjectOutcome.create(
      name: "A1.2.2.1 Describe, compute, and/or use the rate of change (slope) of a line.",
      subject_id: algebra_I_9.id,
      essential: true
    )
    algebra_los << SubjectOutcome.create(
      name: "A1.2.2.2 Analyze and/or interpret data on a scatter plot.",
      subject_id: algebra_I_9.id,
      essential: true
    )
    algebra_los << SubjectOutcome.create(
      name: "2.3.1 Use measures of dispersion to describe a set of data.",
      subject_id: algebra_I_9.id,
      essential: true
    )
    algebra_los << SubjectOutcome.create(
      name: "A1.2.3.2 Use data displays in problem-solving settings and/or to make predictions.",
      subject_id: algebra_I_9.id,
      essential: true
    )
    algebra_los << SubjectOutcome.create(
      name: "A1.2.3.3 Apply probability to practical situations.",
      subject_id: algebra_I_9.id,
      essential: true
    )

    puts ("Create Section Outcomes for Algebra")

    algebra_sos=[]
    algebra_los.each_with_index do |subject_outcome, ix|
      # create section outcome for block 1
      algebra_sos << SectionOutcome.create(
        subject_outcome_id: subject_outcome.id,
        section_id: algebra_I_9_1.id,
        position: ix+1,
        marking_period: 2 ** (ix / 4), # Bitmask! 0->1(mp1), 1->2(mp2), 2->4(mp3), 3->8(mp4)
        active: true,
        minimized: false
      )
      # create section outcome for block 2
      algebra_sos << SectionOutcome.create(
        subject_outcome_id: subject_outcome.id,
        section_id: algebra_I_9_2.id,
        position: ix+1,
        marking_period: 2 ** (ix / 4), # Bitmask! 0->1(mp1), 1->2(mp2), 2->4(mp3), 3->8(mp4)
        active: true,
        minimized: false
      )
      # create section outcome for block 3
      algebra_sos << SectionOutcome.create(
        subject_outcome_id: subject_outcome.id,
        section_id: algebra_I_9_3.id,
        position: ix+1,
        marking_period: 2 ** (ix / 4), # Bitmask! 0->1(mp1), 1->2(mp2), 2->4(mp3), 3->8(mp4)
        active: true,
        minimized: false
      )
      break if ix >= 7    # only load the first two semesters of LOs to each section
    end

    section_outcomes = english_sos + biology_sos + algebra_sos

    puts "section_outcomes.count: #{section_outcomes.count}"

    ###########################################################
    # create 4 evidences / ESOs per section outcome

    e_ratings = ["R","Y","U","M","G","G","G","G","G","G","G","G"]
    eh_ratings = ["R","Y","U","M","B","B","B","B","G","G","G","G"]

    evid_seq = 1

    section_outcomes.each do |so|

      puts ("add evid, eso, and ratings for # #{so.id} - #{so.section.name} | #{so.section.line_number} @ #{so.position}")

      evidence_types.each_with_index do |et, ix| 
        puts "*** et: #{et.name}"
        e = Evidence.create(
          section_id: so.section_id,
          name: "Sample Evidence #{evid_seq} (#{et_levels[ix]})",
          description: "Basically, evidences are homework assignments, tests, quizzes, etc.",
          assignment_date: DateTime.now,
          active: true,
          evidence_type_id: et.id,
          reassessment: false
        )
        eso = EvidenceSectionOutcome.create(
          evidence_id: e.id,
          section_outcome_id: so.id
        )
        # evidence_section_outcomes << eso
        evid_seq += 1

        if so.position < 6
          cur_ratings = (ix > 1) ? eh_ratings : e_ratings
          if so.position != 4 || ix != 2
            students.each do |student|
              # **** note this creates extra sor and esors that are inaccessible - should clean this up ****
              # if there is an enrollment for student and so.section_id
              rating = cur_ratings[Random.rand(12)]
              esor = EvidenceSectionOutcomeRating.create(
                rating: rating,
                student_id: student.id,
                evidence_section_outcome_id: eso.id,
                comment: ""
              )
              sorating = "H" if ["B"].include?(rating)
              sorating = "P" if ["G"].include?(rating)
              sorating = "N" if ["Y","R"].include?(rating) 
              sorating = "U" if ["U","M"].include?(rating)
              if ix == 3 && so.position < 5
                SectionOutcomeRating.create(
                  rating: sorating,
                  student_id: student.id,
                  section_outcome_id: so.id
                )
              end
            end
          end
        end

      end
      
    end

    puts "Done"
  end
end