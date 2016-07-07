#encoding: utf-8

# stem_egypt_training_data.rake
# to create school (no ratings): $ bundle exec rake stem_egypt_training_data:create_school
# to delete: $ bundle exec rake stem_egypt_training_data:delete_training_school

# NOTE: do not call tasks within tasks without changing the error handling to use 'raise' not 'next'

NUM_TEACHERS = 20 # number of teachers per subject
SECTS_PER_TEACHER = 2
STUDENTS_PER_SECTION = 15

###########################################################
# create 4 evidences / ESOs per section outcome per student enrolled

# For evidence Types R and BA, with no Blue rating (2/3 green, 1/3 others)
e_ratings = ["R","Y","U","M","G","G","G","G","G","G","G","G"]

# Strategic Evidence Type (ST) with Blue rating (1/3 green, 1/3 blue, 1/3 others)
eh_ratings = ["R","Y","U","M","B","B","B","B","G","G","G","G"]

namespace :stem_egypt_training_data do
  desc "Create demo data with keystone assessment anchors as Learning Outcomes."

  task load_training_school: :environment do

    ###########################################################
    # check to make sure training school exists and is empty
    # note: load_training_school task empties school

    sch_test = School.where(id: 2)
    if sch_test.count == 0
      puts "!!!!!/nERROR: Training School does not exist/n!!!!!"
      next
    else
      school = sch_test.first
    end

    sch_test = User.where(school_id: 2)
    if sch_test.count > 0
      puts "!!!!!/nERROR: Training School already loaded/n!!!!!"
      next
    end

    disciplines = []

    db_disc = Discipline.where(name: "Language")
    if db_disc.count > 0
      language = db_disc.first
    else
      language = Discipline.create(name: "Language")
    end
    disciplines << language

    db_disc = Discipline.where(name: "Mathematics")
    if db_disc.count > 0
      mathematics = db_disc.first
    else
      mathematics = Discipline.create(name: "Mathematics")
    end
    disciplines << mathematics

    db_disc = Discipline.where(name: "Science")
    if db_disc.count > 0
      science = db_disc.first
    else
      science = Discipline.create(name: "Science")
    end
    disciplines << science


    puts "create schools, school year and users"

    puts("School: #{school.inspect}")

    this_year = Time.now.year
    next_year = this_year + 1
    school_year = SchoolYear.new()
    school_year.name = "#{this_year.to_s}-#{next_year.to_s.last(2)}"
    school_year.school_id = school.id
    school_year.starts_at = Date.parse("#{this_year.to_s}-09-01")
    school_year.ends_at = Date.parse("#{next_year.to_s}-06-21")
    if !school_year.save
      puts "!!!!!/nERROR: Create school got error: #{school.errors.full_messages}/n!!!!!"
      next
    end

    school.school_year_id = school_year.id
    if !school.save
      puts "!!!!!/nERROR: Update school year got error: #{school.errors.full_messages}/n!!!!!"
      next
    end

    puts("School: #{school.inspect}")
    puts("school_year: #{school_year.inspect}")


    ###########################################################
    # create the special users

    puts("Create special users")

    school_admins = SchoolAdministrator.where(username: "eth_admin")
    if school_admins.count == 0
      school_admin = SchoolAdministrator.new()
      school_admin.username = "eth_admin"
      school_admin.first_name = "Eth"
      school_admin.last_name = "Admin"
      school_admin.school_id = school.id
      school_admin.email = 'info@21pstem.org'
      school_admin.password = "password"
      school_admin.password_confirmation = "password"
      if !school_admin.save
        puts "!!!!!/nERROR: create school admin error #{school_admin.errors.full_messages}/n!!!!!"
        next
      end
    elsif school_admins.count == 1
      school_admin = school_admins.first
    else
      puts "!!!!!/nERROR: System Error - multiple eth_admin records"
      next
    end

    counselors = Counselor.where(username: "eth_counselor")
    if counselors.count == 0
      counselor = Counselor.new()
      counselor.username = "eth_counselor"
      counselor.first_name = "Eth"
      counselor.last_name = "Counselor"
      counselor.school_id = school.id
      counselor.password = "password"
      counselor.password_confirmation = "password"
      if !counselor.save
        puts "!!!!!/nERROR: create school Counselor error #{school_admin.errors.full_messages}/n!!!!!"
        next
      end
    elsif counselors.count == 1
      counselor = counselors.first
    else
      puts "!!!!!/nERROR: System Error - multiple eth_counselor records"
      next
    end

    subject_managers = Teacher.where(username: "eth_subject_manager")
    if subject_managers.count == 0
      subject_manager = Teacher.new()
      subject_manager.username = "eth_subject_manager"
      subject_manager.first_name = "Eth"
      subject_manager.last_name = "Subject Manager"
      subject_manager.school_id = school.id
      subject_manager.password = "password"
      subject_manager.password_confirmation = "password"
      if !subject_manager.save
        puts "!!!!!/nERROR: create subject_manager error #{subject_manager.errors.full_messages}/n!!!!!"
        next
      end
    elsif subject_managers.count == 1
      subject_manager = subject_managers.first
    else
      puts "!!!!!/nERROR: System Error - multiple eth_counselor records"
      next
    end

    subject_names = ['Arabic', 'Biology', 'Chemistry', 'Computer Science', 'Earth Science', 'English', 'French', 'German', 'Math', 'Mechanics', 'Physics']
    subject_lead_chars = %w(ar b ch cs es en fr ge ma me p) # characters for username
    subj_discs = [0,2,2,2,2,0,0,0,1,2,2] # index to disciplines array

    if subject_names.length != subject_lead_chars.length ||
      subject_names.length != subj_discs.length
      puts "!!!!!/nERROR: Invalid subject creation arrays #{subject_names.length} #{subject_lead_chars.length} #{subj_discs.length}/n!!!!!"
      next
    end
    # teachers array by subject (0-9) and sequence (0-(subject_names.length-1))
    # teachers = Hash.new { |k, v| k[v] = Array.new(NUM_TEACHERS) }
    teachers = Array.new(subject_names.length) { Array.new(NUM_TEACHERS) }

    puts("Create #{NUM_TEACHERS} teachers per subject")
    (0..(subject_names.length-1)).each do |subj|
      (0..(NUM_TEACHERS - 1)).each do |seq|
        un = subject_lead_chars[subj]+'teacher'+(seq+1).to_s
        t = Teacher.new()
        t.username = un
        t.first_name = subject_names[subj]
        t.last_name = "Teacher#{seq+1}"
        t.school_id = school.id
        t.password = "password"
        t.password_confirmation = "password"
        if !t.save
          puts "!!!!!/nERROR: create teacher #{subject_names[subj][0].downcase}teacher#{(seq+1).to_s} error #{t.errors.full_messages}/n!!!!!"
          next
        end
        teachers[subj][seq] = t
      end
      puts("teachers[#{subj}]: (#{subject_names[subj]}): #{(teachers[subj].map{ |t| t.username}).inspect }")
    end

    # students hash by student grouping (1- (NUM_TEACHERS * SECTS_PER_TEACHER) and sequence (1-STUDENTS_PER_SECTION)

    # students = Hash.new { |k, v| k[v] = Hash.new(0) }
    students = Array.new(NUM_TEACHERS * SECTS_PER_TEACHER) { Array.new(STUDENTS_PER_SECTION) }

    puts("create students by group - NUM_TEACHERS teachers times SECTS_PER_TEACHER subjects, with STUDENTS_PER_SECTION students per group")
    # create NUM_TEACHERS * SECTS_PER_TEACHER grouping
    seq_num = 0
    ( 0..(NUM_TEACHERS * SECTS_PER_TEACHER - 1) ).each do |g|
      # create STUDENTS_PER_SECTION per grouping
      (0..NUM_TEACHERS).each do |n|
        seq_num += 1
        un = "eth_student#{seq_num}"
        s = Student.new()
        s.username = un
        s.first_name = Faker::Name.first_name
        s.last_name = Faker::Name.last_name
        s.grade_level = 1
        s.gender = ["M", "F"][n % 2]
        s.school_id = school.id
        s.password = "password"
        s.password_confirmation = "password"
        if !s.save
          puts "!!!!!/nERROR: create student error #{s.errors.full_messages}/n!!!!!"
          next
        end
        students[g][n] = s
      end
      puts("students[#{g}]: #{(students[g].map{ |s| s.username}).inspect}")
    end


    ###########################################################
    # create the courses and enroll students and assign the teacher.

    puts ("Create Subjects and Sections")

    subjects = Array.new(subject_names.length)
    subject_sections = Array.new(subject_names.length) {Array.new(NUM_TEACHERS * SECTS_PER_TEACHER)}

    subject_names.each_with_index do |subj, ix|
      puts ("Create  Subject for #{subj} at #{ix}")
      s = Subject.new()
      s.name = subj
      puts ("subject_discipline: #{disciplines[subj_discs[ix]].inspect}")
      s.discipline_id = disciplines[subj_discs[ix]].id
      s.school_id = school.id
      s.subject_manager_id = subject_manager.id
      if !s.save
        puts "!!!!!/nERROR: create subject error #{s.errors.full_messages}/n!!!!!"
        next
      end
      subjects[ix] = s

      subj_teachers = teachers[ix]

      # create sections per subject so each of NUM_TEACHERS teachers/subject has SECTS_PER_TEACHER sections each)
      ( 0..(NUM_TEACHERS * SECTS_PER_TEACHER - 1) ).each do |sect|

        # create the section
        s = Section.new()
        s.line_number = "Section #{sect}"
        s.subject_id = subjects[ix].id
        s.school_year_id = school_year.id
        s.message = ["Homework Due Thursday!!", "Quiz on Friday !!!!"][sect % 2]
        if !s.save
          puts "!!!!!/nERROR: create section error #{s.errors.full_messages}/n!!!!!"
          next
        end
        subject_sections[ix][sect] = s

        # two sections per teacher
        teach = (sect/SECTS_PER_TEACHER).floor
        # puts "assign teacher #{teach}"

        # assign a teacher to it
        ta = TeachingAssignment.new()
        ta.teacher_id = subj_teachers[teach].id
        ta.section_id = subject_sections[ix][sect].id
        if !ta.save
          puts "!!!!!/nERROR: create teaching assignment error #{ta.errors.full_messages}/n!!!!!"
          next
        end

        # enroll students into it
        students[sect].each_with_index do |student, iy|
          e = Enrollment.new()
          e.student_id = student.id
          e.section_id = subject_sections[ix][sect].id
          e.student_grade_level = student.grade_level
          if !e.save
            puts "!!!!!/nERROR: create enrollment error #{e.errors.full_messages}/n!!!!!"
            next
          end
        end

      end

    end

    puts "Done"

  end # end create_school


  task create_training_los: :environment do

    ###########################################################
    # check to make sure school already exists
    sch_test = School.where(name: "Stem Egypt Training High School", acronym: 'ETH')
    if sch_test.count == 0
      puts "!!!!!/nERROR: School doesn't exist - run stem_egypt_training_data:create /n!!!!!"
      next
    else
      school = sch_test.first
    end

    school_year = SchoolYear.where(id: school.school_year_id).first
    if school_year.errors.count > 0
      puts "!!!!!/nERROR: Cannot find School Year/n!!!!!"
      next
    end

    ###########################################################
    # get all Subject Outcomes for the school
    subject_ids = Subject.where(school_id: school.id).pluck(:id)
    subject_outcomes = SubjectOutcome.where(subject_id: subject_ids)
    if subject_outcomes.count > 0
      input = ''
      STDOUT.puts "Subject Outcomes already exist.  If you wish to recreate them, hit enter to continue"
      input = STDIN.gets.chomp
      if input != ""
        puts "!!!!!\nERROR: Subject Outcome create cancelled by user.\n!!!!!"
        next
      end
    end

    ###########################################################
    # get all Section Outcomes for the school
    section_outcomes = SectionOutcome.includes(:section).where('sections.school_year_id = ?', school_year.id)
    if section_outcomes.count > 0
      input = ''
      STDOUT.puts "Section Outcomes already exist.  If you wish to recreate them, hit enter to continue"
      input = STDIN.gets.chomp
      if input != ""
        puts "!!!!!\nERROR: Section Outcome create cancelled by user.\n!!!!!"
        next
      end
    end

    # "Course","Grade","Semester","LO Code:","Learning Outcome Name"
    all_los = [

      ['Arabic', 1, 1, '', "Ar.1.01 - Applying grammatical rules during speaking, discussion and presentations to apply what they were taught.1. تطبيق القواعد النحوية \اثناء الحديث والمجادلة العرض التقديمى بحيث يوظف ما درسه عمليا."],
      ['Arabic', 1, 1, '', "Ar.1.02 - Applying Rhetorical Analysis to literary and poetic texts that deal with the emotions and the literary direction of the writer.2. تحليل النص الأدبى النثرى أو الشعرى تحليلا بلاغيا يتناول عاطفة الاديب واتجاهه الأدبى والصور البلاغية وعلم البديع و"],
      ['Arabic', 1, 1, '', "AR.1.03 - Explore the writer’s personal and literary characteristics and the influence of the surrounding environment for each literary work.6. إستنباط خصائص أسلوب الأديب وسمات شخصيته وأثر البيئة المحيطة من كل عمل أدبى."],
      ['Arabic', 1, 1, '', "Ar.1.04 - Excelling in giving speeches, reading aloud, and discussion, taking into account the correct pronunciation, signals, and intonation for persuasion.9. البراعة فى الإلقاء أو القراءة الجهرية أو المناقشة مع مراعاة سلامة النطق والإشارة وتنغيم الصوت"],
      ['Arabic', 1, 1, '', "AR.1.05 - Applying grammatical rules during speaking, discussion and presentations to apply what they were taught.1. تطبيق القواعد النحوية \اثناء الحديث والمجادلة العرض التقديمى بحيث يوظف ما درسه عمليا."],
      ['Arabic', 1, 1, '', "AR.1.06 - Derive the human values from different lessons that should enable them to be enlightened and drive them to improve the world.5. استخلاص القيم الإنسانية المتعلمة من الدروس المختلفة والتى من شأنها إنارة العقول ودفع البشرية نحو التقدم."],
      ['Arabic', 1, 2, '', "AR.1.07 - Applying critical analysis and criticism to work of prose and express a critical opinion using evidence to support their opinions.3. نقد الأعمال القصصية وتحليلها وابدء رأى نقدى بناء مع ايجاد براهين لذلك الرأى."],
      ['Arabic', 1, 2, '', "AR.1.08 - Explore the writer’s personal and literary characteristics and the influence of the surrounding environment for each literary work.6. إستنباط خصائص أسلوب الأديب وسمات شخصيته وأثر البيئة المحيطة من كل عمل أدبى."],
      ['Arabic', 1, 2, '', "AR.1.09 - Mastering writing creative literary work of different literary topics to reflect the student’s ability to absorb the major challenges facing Egypt using the rules of the language.10. التمكن من إبداع موضوعات أدبية مختلفة تعكس مدى قدرته على إستي"],
      ['Arabic', 1, 2, '', "AR.1.10 - Applying Rhetorical Analysis to literary and poetic texts that deal with the emotions and the literary direction of the writer.2. تحليل النص الأدبى النثرى أو الشعرى تحليلا بلاغيا يتناول عاطفة الاديب واتجاهه الأدبى والصور البلاغية وعلم البديع و"],
      ['Arabic', 1, 2, '', "AR.1.11 - Excelling in giving speeches, reading aloud, and discussion, taking into account the correct pronunciation, signals, and intonation for persuasion.9. البراعة فى الإلقاء أو القراءة الجهرية أو المناقشة مع مراعاة سلامة النطق والإشارة وتنغيم الصوت"],
      ['Arabic', 1, 2, '', "AR.1.12 - Applying grammatical rules during speaking, discussion and presentations to apply what they were taught.1. تطبيق القواعد النحوية \اثناء الحديث والمجادلة العرض التقديمى بحيث يوظف ما درسه عمليا."],
      ['Biology', 1, 1, '', "BI.1.01 - Analyze the factors which contribute to the eradication of diseases
      1. explain the factors which contribute to the spread and the control of each disease
      2. explain the mode of transmission of each disease
      3. classify disease as infectious or no"],
      ['Biology', 1, 1, '', "BI.1.02 - Compare and contrast the structures within the cells of plants, animals, Protista and bacteria which function to enable the cell to live."],
      ['Biology', 1, 1, '', "BI.1.03 - Connect the structure of a healthy cell membrane to the functions it performs
      1. Develop an explanation of the structure of the cell membrane to include how the structure enables the processes of diffusion and osmosis to occur
      2. Describe the na"],
      ['Biology', 1, 1, '', "BI.1.04 - Create a model which shows the relationship of DNA and RNA in protein synthesis
      1. DNA structure
      2. Base pairing roles
      3. The mechanism of protein synthesis"],
      ['Biology', 1, 1, '', "BI.1.05 - Investigate the functions of different classes of proteins and the factors affecting their optimal performance
      1. Know the structure of protein
      2. Differentiate the classes of proteins and their functions
      3. Know how the structure of an enzyme d"],
      ['Biology', 1, 1, '', "BI.1.06 - Create a model which outlines the cell cycle in controlled and uncontrolled cell divisions
      1. Uncontrolled cell division resulting in cancer"],
      ['Biology', 1, 2, '', "BI.1.07 - Create your own experiment to investigate a factor that affects photosynthesis and/or respiration
      Use the steps of experimental design"],
      ['Biology', 1, 2, '', "BI.1.08 - Create a model that shows the interdependence of living organisms within an ecosystem
      Describe energy loss between trophic levels and its relation to the number of trophic levels
      Explain the roles of producers and consumers in a food web
      Conside"],
      ['Biology', 1, 2, '', "BI.1.09 - Connect the cycling of carbon to global climate change
      • Matter is conserved within nature
      • Forms of carbon within the carbon cycle.
      • Processes that contribute to the carbon cycle.
      •Connection between the water cycle and the carbon cycle
      •Ef"],
      ['Biology', 1, 2, '', "BI.1.10 - Analyze how natural and human caused events can unbalance populations within an ecosystem and make a judgments about the ways to rebalance the ecosystem
      • Describe natural disasters which cause unbalancing of ecosystems.
      • Describe human caused"],
      ['Biology', 1, 2, '', "BI.1.11 - Analyze an ecosystem in Egypt that has become unbalanced and suggest effective interventions"],
      ['Chemistry', 1, 1, '', "CH.1.01 - Students will be able to describe what characterizes science and its methods and use a quantitative observations with measurement by SI units."],
      ['Chemistry', 1, 1, '', "CH.1.02 - Demonstrate understanding of atomic structure, subatomic particles, their arrangements and the evidence that scientists that enabled scientists to discover them."],
      ['Chemistry', 1, 1, '', "CH.1.03 - Students must demonstrate their understanding of the electromagnetic spectrum and the particle nature of light by explaining how atoms of different elements are able to produce light of different colors;"],
      ['Chemistry', 1, 1, '', "CH.1.04 - Through laboratory investigations develop operational definitions of chemical elements, and differentiate between metals and nonmetals, and chemical and physical properties of unknown elements based on their position and atomic structures in the"],
      ['Chemistry', 1, 1, '', "CH.1.05 - Describe how to determine chemical behavior according to valence electrons and how and why atoms interact with each other."],
      ['Chemistry', 1, 1, '', "CH.1.06 - Select and use data to construct an argument for the existence of strong nuclear forces."],
      ['Chemistry', 1, 2, '', "CH.1.07 - Students must calculate quantities of products formed from known quantities of reactants and be able to discuss their precision and accuracy."],
      ['Chemistry', 1, 2, '', "CH.1.08 - Investigate four types of chemical reactions, generate and test for hydrogen, oxygen and carbon dioxide and determine the most effective ratio of hydrogen to oxygen for propulsion of a small rocket."],
      ['Chemistry', 1, 2, '', "CH.1.09 - Students will use their understanding of the metal activity series to explain why metals are found as they are in nature and discuss considerations (such as exposure to different kinds of solutions) for the use of metals in industry, constructio"],
      ['Chemistry', 1, 2, '', "CH.1.10 - Students will use two and three dimensional models and their understanding of bond polarity to illustrate polar and non-polar inter-molecular forces."],
      ['Chemistry', 1, 2, '', "CH.1.11 - Students will examine a variety of commercial batteries and use their understanding of electrochemistry to explain how they work and why the manufacturers used the materials they did."],
      ['Chemistry', 1, 2, '', "CH.1.12 - Students will determine, explain and illustrate how energy and disorder change during physical and chemical processes."],
      ['Earth Science', 1, 1, '', "ES.1.01 - The students will describe the interrelationships between the different branches of earth science and the integration of geology within other sciences"],
      ['Earth Science', 1, 1, '', "ES.1.02 - Students are able to examine common minerals and identify them and differentiate them from other common minerals."],
      ['Earth Science', 1, 1, '', "ES.1.03 - Students will examine and interpret the textural and compositional characteristics of igneous rocks and interpret igneous rock textures and mineral composition."],
      ['Earth Science', 1, 1, '', "ES.1.04 - Students will examine and interpret the textural and compositional characteristics of sedimentary rocks and interpret sedimentary rock textures, mineral composition and depositional environments."],
      ['Earth Science', 1, 1, '', "ES.1.05 - Students will examine and interpret the textural and compositional characteristics of metamorphic rocks and interpret textures and factors that effect metamorphic processes."],
      ['Earth Science', 1, 1, '', "ES.1.06 - Students will analyze and identify the earth materials that are used as a resource for modern building, and integrate design criteria and material properties in choosing materials for engineering design."],
      ['Earth Science', 1, 2, '', "ES.1.07 - Students will analyze and identify common ore minerals that are used as a resource for modern industries."],
      ['Earth Science', 1, 2, '', "ES.1.08 - Students will understand the different resources used by different countries to meet their energy needs."],
      ['Earth Science', 1, 2, '', "ES.1.09 - Students will be able to recognize the processes by which fossil fuels (coal) are extracted and processed for human use."],
      ['Earth Science', 1, 2, '', "ES.1.10 - Students will be able to recognize the processes by which fossil fuels (petroleum and natural gas) are extracted and processed for human use."],
      ['Earth Science', 1, 2, '', "ES.1.11 - Students will be able to evaluate environmental impacts of fossil fuel resource use and suggest innovative alternatives."],
      ['Earth Science', 1, 2, '', "ES.1.12 - Students will evaluate potential renewable energy sources in Egypt to replace dependence upon fossil fuels."],
      ['English', 1, 1, '', "EN.1.01 - Students will be able to identify gist and main ideas."],
      ['English', 1, 1, '', "EN.1.02 - Students will be able to reflect on ideas"],
      ['English', 1, 1, '', "EN.1.03 - Students will be able to distinguish among facts and speculation in a text."],
      ['English', 1, 1, '', "EN.1.04 - Students will be able to use technology to produce, publish and update individual or shared writing products."],
      ['English', 1, 1, '', "EN.1.05 - Students will be able to produce clear and coherent writing, in which the development, organization, and style are appropriate to task, purpose and audience."],
      ['English', 1, 2, '', "EN.1.06 - Students will be able to read, comprehend and appreciate the values, beliefs and practices of both national and target cultures."],
      ['English', 1, 2, '', "EN.1.07 - Students will be able to interpret a work of literature and relate the information to contemporary"],
      ['English', 1, 2, '', "EN.1.08 - Students will be able to participate effectively in discussions and debates (one-on-one, in groups, and teacher-led) with diverse topics and issues."],
      ['English', 1, 2, '', "EN.1.09 - Students will be able to determine the meaning of words and phrases as they are used in the text."],
      ['English', 1, 2, '', "EN.1.10 - Students will be able to identify and correctly use idioms, phrasal verbs, collocations and affixes."],
      ['English', 1, 2, '', "EN.1.11 - Students will be able to use appropriate vocabulary to describe people, places, events and experiments."],
      ['French', 1, 1, '', "FR.1.01 - L'apprenant reponds a des demandes de renseignements personnelsmde base et a des questions sur ses besoins immediates dans des situations courantes"],
      ['French', 1, 1, '', "FR.1.02 - l'apprenant sait ecrire les donnees personnelles a son sujet et au sujet de sa famille"],
      ['French', 1, 1, '', "FR.1.03 - L'apprenant sera capable de: -S'orienter et se deplacer.  -Se reseigner sur les moyens de transport.  -Comparer"],
      ['French', 1, 1, '', "FR.1.04 - Etre capable d'employer les verbs (avoir, aller, arriver, habiter)"],
      ['French', 1, 1, '', "FR.1.05 - Distinguer entre les femenin et le masculin"],
      ['French', 1, 1, '', "FR.1.06 - Nommer les traits du visage, les couleurs, les vetements, les professions et les membre de la familles inclus dans le livre"],
      ['French', 1, 2, '', "FR.1.07 - Etre capable de s'informer sur les caracters d'une personne"],
      ['French', 1, 2, '', "FR.1.08 - Nommer les qualites et les defauts."],
      ['French', 1, 2, '', "FR.1.09 - Nommer les signes de l'horiscope et les astres"],
      ['French', 1, 2, '', "FR.1.10 - Nommer les 4 saisons de l'annee, les mois de l'annee et les points cardinaux"],
      ['French', 1, 2, '', "FR.1.11 - Nommer les pieces de la maison et les meubles (inclus dans le livre)"],
      ['French', 1, 2, '', "FR.1.12 - Preciser le lieu"],
      ['German', 1, 1, 'DE.1.01', "Die Schüler können (1-Etwas buchstabieren, 2-eine Visitenkarte lesen, 3-ein Anmeldeformular ausfüllen)"],
      ['German', 1, 1, 'DE.1.02', "Schüler können (1.Zahlen von null bis 20 zählen, 2.ein Formular ausfüllen, 3.sich und andere Vorstellen)"],
      ['German', 1, 1, 'DE.1.03', "Die Schüler können (1. von 21 - bis  100 zählen, 2. nach Preisen, Gewichten und Maßeinheiten Fragen  und beantworten, 3. Vorlieben ausdrücken.)"],
      ['German', 1, 1, 'DE.1.04', "Die Schüler können (1. Zahlen von : 100 -bis 1.000.000 zählen, 2.Wohnungsanzeigen  suchen, 3.einen Zeitungsartikel verstehen)"],
      ['German', 1, 1, 'DE.1.05', "1.Über die Freizeit und seine Hobbys sprechen, 2. einen Wetterbericht lesen"],
      ['German', 1, 2, 'DE.1.06', "über seine Fähigkeiten und Wünsche berichten"],
      ['German', 1, 2, 'DE.1.07', "Schüler kann (1. über seinen Tagesablaus berichten, 2.Öffnungszeiten verstehen)"],
      ['German', 1, 2, 'DE.1.08', "-Stellenanzeigen verstehen, - Berufsbeschreibungen"],
      ['German', 1, 2, 'DE.1.09', "1  Informationenbroschüren  verstehen, 2. Informationen und Erklärungen bitteb, nachfragen
"],
      ['German', 1, 2, 'DE.1.10', "über Aktivitäten und Ereignisse in der Vergangenheit berichten
über+ Lernziele und Lernstrategien sprechen"],
      ['Math', 1, 1, '', "MA.1.01 - Create, interpret and analyze trigonometric ratios that model real-world situations."],
      ['Math', 1, 1, '', "MA.1.02 - Apply the relationships between 2-D and 3-D objects in modeling situations"],
      ['Math', 1, 1, '', "MA.1.03 - Understand similarity and use the concept for scaling to solve problems"],
      ['Math', 1, 1, '', "MA.1.04 - Apply volume formulas (pyramid, cones, spheres, prisms)"],
      ['Math', 1, 1, '', "MA.1.05 - Create, interpret and analyze functions, particularly linear and step functions that model real-world situations."],
      ['Math', 1, 1, '', "MA.1.06 - Analyze, display and describe quantitative data with a focus on standard deviation."],
      ['Math', 1, 2, '', "MA.1.07 - Create, interpret and analyze quadratic functions that model real-world situations."],
      ['Math', 1, 2, '', "MA.1.08 - Create, interpret and analyze exponential and logarithmic functions that model real-world situations."],
      ['Math', 1, 2, '', "MA.1.09 - Create, interpret and analyze trigonometric functions that model real-world situations."],
      ['Math', 1, 2, '', "MA.1.10 - Prove and apply trigonometric identities"],
      ['Math', 1, 2, '', "MA.1.11 - Create, interpret and analyze systems of linear functions that model real-world situations."],
      ['Math', 1, 2, '', "MA.1.12 - Apply determinants and their properties in real-world situations"],
      ['Mechanics', 1, 1, '', "ME.1.01 - Students will use position, displacement, average and instantaneous velocity, average and instantaneous acceleration to describe 1-dimensional motion of an object."],
      ['Mechanics', 1, 1, '', "ME.1.02 - Students will use kinematic equations to understand and predict 1-dimensional motion of objects under constant acceleration,including vertical (free-fall) motion under gravity."],
      ['Mechanics', 1, 1, '', "ME.1.03 - Students will understand the importance of reference frames and use relative velocity to describe the motions of 2 objects with respect to each other in 1-D"],
      ['Mechanics', 1, 1, '', "ME.1.04 - Students will be able to use vector concepts to extend 1-d kinematics to motion in 2-D."],
      ['Mechanics', 1, 1, '', "ME.1.05 - Students will be able to analyze and solve 2-D projectile problems in the absence of air resistance"],
      ['Mechanics', 1, 2, '', "ME.1.06 - Students will be able to use Newtown's 1st Law and vector algebra to analyze systems in translational equilibrium."],
      ['Mechanics', 1, 2, '', "ME.1.07 - Students will experimentally justify Newton's 2nd law and use it to mathematically predict motion of objects in 1-D"],
      ['Mechanics', 1, 2, '', "ME.1.08 - Students will be able to use Newtown's 2nd Law and vector algebra to analyze motion of objects in 2-D"],
      ['Mechanics', 1, 2, '', "ME.1.09 - Students will be able to analyze circular motion of an object using concepts of centripetal acceleration and centripetal force"],
      ['Physics', 1, 1, '', "PH.1.01 - Students will be able to make measurements precisely and accurately using a variety of measurement tools."],
      ['Physics', 1, 1, '', "PH.1.02 - Students will be able to use Newton's 3rd Law to identify the forces of interaction that exist between pairs of objects (Newtonian pairs)"],
      ['Physics', 1, 1, '', "PH.1.03 - Students will be able to predict an object's motion based on the forces that are acting on it."],
      ['Physics', 1, 1, '', "PH.1.04 - Students will be able to model the gravitational force on an object near the earth as proportional to the object's mass , with constant of proportionality g, the gravitational field strength."],
      ['Physics', 1, 1, '', "PH.1.05 - Students will be able to determine the conditions for stability of extended rigid bodies by considering translational and rotational equilibrium"],
      ['Physics', 1, 2, '', "PH.1.06 - Students will understand that certain material objects (e.g. springs that follow Hooke's Law) generate restoring forces that act to maintain them in an equilibrium shape."],
      ['Physics', 1, 2, '', "PH.1.07 - Students will be able to predict an object's motion when it is subject to a restoring force"],
      ['Physics', 1, 2, '', "PH.1.08 - Students will be able to use pressure difference between two points of a fluid and Newton's laws to analyze behavior of that fluid."],
      ['Physics', 1, 2, '', "PH.1.09 - Students will be able to apply principles of fluid dynamics to determine pressure and velocity in a variety of typical fluid systems"],
      ['Physics', 1, 2, '', "PH.1.10 - Students will be able to design a system for efficient energy production using concepts of temperature, heat, and thermal energy."],
      ['Physics', 1, 2, '', "PH.1.11 - Students will be able to analyze energy flow in typical heating and cooling applications by applying the 1st Law of Thermodynamics."]
    ]

    ###########################################################
    # create a hash by subject names
    subj_by_name = Hash.new
    Subject.where(school_id: school.id).each do |subj|
      subj_by_name[:"#{subj.name}"] = subj
    end
    STDOUT.puts "subj_by_name: #{subj_by_name.inspect}"

    # validate subject matching of above Learning Outcomes.
    all_los.each do |lo|
      subj = subj_by_name[lo[0].to_sym]
      raise "!!!!!\nERROR: Invalid subject: #{lo[0]}.\n!!!!!" if !subj
    end

    # # confirm to go ahead.
    # input = ''
    # STDOUT.puts "If all subjects are properly matched, hit enter to continue"
    # input = STDIN.gets.chomp
    # if input != ""
    #   puts "!!!!!\nERROR: create_learning_outcomes cancelled by user.\n!!!!!"
    #   next
    # end

    # Create Subject Outcome for each of the above Learning Outcomes.
    # ["Course","Grade","Semester","LO Code:","Learning Outcome"]
    all_los.each do |lo|
      subj = subj_by_name[lo[0].to_sym]
      if subj
        tmp_subjo = SubjectOutcome.new
        tmp_subjo.name = lo[4]
        STDOUT.puts "tmp_subjo.lo_code: #{tmp_subjo.lo_code}, tmp_subjo.description: #{tmp_subjo.description}"
        has_subjo = SubjectOutcome.where(subject_id: subj.id, lo_code: tmp_subjo.lo_code, description: tmp_subjo.description)
        if has_subjo.count == 0
          subjo = SubjectOutcome.new
          subjo.name = lo[4]
          subjo.marking_period = lo[2]
          subjo.subject_id = subj.id
          raise("ERROR: error saving Subject Outcome #{subj.name} - #{lo[4]}") if !subjo.save
        else
          STDOUT.puts "WARNING: LO Exists already: #{subj.name} - #{lo[4]}"
          subjo = has_subjo.first
        end
        # copy LOs to all sections corresponding with this subject
        Section.where(subject_id: subj.id).each do |sect|
          has_secto = SectionOutcome.where(section_id: sect.id, subject_outcome_id: subjo.id)
          if has_secto.count > 0
            STDOUT.puts "WARNING: LO for Section already exists in section: #{sect.line_number}"
          else
            secto = SectionOutcome.new
            secto.section_id = sect.id
            secto.subject_outcome_id = subjo.id
            secto.marking_period = lo[2]
            raise("ERROR: error saving Section Outcome #{subj.name} - #{lo[4]} - #{sect.line_number} - error: #{secto.errors.full_messages}") if !secto.save
          end
        end
      else
        raise "!!!!!\nERROR: Invalid subject: #{lo[0]}.\n!!!!!"
      end
    end

    puts "Done"

  end # end create_learning_outcomes

  task create_training_ratings: :environment do

    ###########################################################
    # check to make sure school already exists
    sch_test = School.where(name: "Stem Egypt Training High School")
    if sch_test.count == 0
      puts "!!!!!/nERROR: School doesn't exist - run stem_egypt_training_data:create /n!!!!!"
      next
    else
      school = sch_test.first
    end

    school_year = SchoolYear.where(id: school.school_year_id).first
    if school_year.errors.count > 0
      puts "!!!!!/nERROR: Cannot find School Year/n!!!!!"
      next
    end

    ###########################################################
    # get all Section Outcomes for the school
    section_outcomes = SectionOutcome.includes(:section).where('sections.school_year_id = ?', school_year.id)
    if section_outcomes.count == 0
      puts "!!!!!\nERROR: Missing Section Outcomes.  Run create_los.\n!!!!!"
      next
    end


    ###########################################################
    # create our evidence types if not there already
    ets=["In Class", "Homework", "Quiz", "Test"]
    # evidence types: Recall, Basic Applcation & Strategic Thinking
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

    # ###########################################################
    # # create 4 evidences / ESOs per section outcome per student enrolled

    # # For evidence Types R and BA, with no Blue rating (2/3 green, 1/3 others)
    # e_ratings = ["R","Y","U","M","G","G","G","G","G","G","G","G"]

    # # Strategic Evidence Type (ST) with Blue rating (1/3 green, 1/3 blue, 1/3 others)
    # eh_ratings = ["R","Y","U","M","B","B","B","B","G","G","G","G"]

    evid_seq = 1

    # confirm to go ahead
    input = ''
    STDOUT.puts "This procedure will create Ratings in the Training School, hit enter to continue"
    input = STDIN.gets.chomp
    if input != ""
      puts "!!!!!\nERROR: create_ratings cancelled by user.\n!!!!!"
      next
    end

    section_outcomes.each do |so|

      puts ("add evid, eso, and ratings for # #{so.id} - #{so.section.name} | #{so.section.line_number} @ #{so.position}")

      evidence_types.each_with_index do |et, ix|
        # puts "*** et: #{et.name}"
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

        if so.position < 7
          cur_ratings = (ix > 1) ? eh_ratings : e_ratings
          if so.position != 4 || ix != 2
            so.section.students.each do |student|
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
  end # end create_ratings

  task refresh_training_school: :environment do

    ###########################################################
    # check to make sure school already exists
    schools = School.where(name: "Stem Egypt Training High School")
    if schools.count == 0
      puts "!!!!!/nERROR: School doesn't exist - run stem_egypt_training_data:create /n!!!!!"
      next
    else
      school = schools.first
    end

    school_year = SchoolYear.where(id: school.school_year_id).first
    if school_year.errors.count > 0
      puts "!!!!!/nERROR: Cannot find School Year/n!!!!!"
      next
    end

    ###########################################################
    # get all Section Outcomes for the school
    section_ids = Section.where(school_year_id: school_year.id).pluck(:id)
    section_outcomes = SectionOutcome.where(section_id: section_ids)
    if section_outcomes.count == 0
      puts "!!!!!\nERROR: Missing Section Outcomes.  Bulk Upload Training Learning Outcomes.\n!!!!!"
      next
    end


    ###########################################################
    # create our evidence types if not there already
    ets=["In Class", "Homework", "Quiz", "Test"]
    # evidence types: Recall, Basic Applcation & Strategic Thinking
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

    STDOUT.puts "e_ratings: #{e_ratings.inspect}"

    evid_seq = 1

    # confirm to go ahead
    input = ''
    STDOUT.puts "This procedure will clear out all Ratings in the Training School, hit enter to continue"
    input = STDIN.gets.chomp
    if input != ""
      puts "!!!!!\nERROR: create_ratings cancelled by user.\n!!!!!"
      next
    end

    schools.each do |s|
      (Section.where(school_year_id: s.school_year_id)).each do |sect|
        (SectionOutcome.where section_id: sect.id).each do |so|
          (EvidenceSectionOutcome.where section_outcome_id: so.id).each do |eso|
            EvidenceSectionOutcomeRating.delete_all(evidence_section_outcome_id: eso.id)
          end
          SectionOutcomeRating.delete_all(section_outcome_id: so.id)
        end
      end
    end

    section_outcomes.each do |so|
      puts ("add ratings for # #{so.id} - #{so.section.name} | #{so.section.line_number} @ #{so.position}")
      EvidenceSectionOutcome.where(section_outcome_id: so.id).each do |eso|
        if so.position < 7
          e_type_name = eso.evidence_type.name
          if ["In Class", "Homework"].include?(e_type_name)
            cur_ratings = e_ratings
          elsif ["Quiz", "Test"].include?(e_type_name)
            cur_ratings = eh_ratings
          else
            raise "invalid rating #{e_type_name}"
          end
          # cur_ratings = (ix > 1) ? eh_ratings : e_ratings

          if so.position != 4 || e_type_name != 'Quiz'
            so.section.students.each do |student|
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
              if e_type_name != 'Test' && so.position < 5
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

    ###########################################################
    # reset all teacher passwords
    STDOUT.puts "Resetting teacher passwords."
    Teacher.where(school_id: school.id).each do |t|

      t.password = 'password'
      t.password_confirmation = 'password'
      t.temporary_password = ''
      t.save
    end
    STDOUT.puts "Done"
  end


  task clear_training_school: :environment do

    # !!!!!\nWARNING: CAUTION MODIFYING THIS CODE - MISTAKE COULD DELETE LIVE DATA ON PRODUCTION SYSTEM. !!!!!!!!

    schools = School.where(
      name: "Stem Egypt Training High School",
      acronym: "ETH"
    )

    if schools.count > 0
      input = ''
      STDOUT.puts "Training School already exist.  If you wish to recreate the School, hit enter to continue"
      input = STDIN.gets.chomp
      if input != ""
        puts "!!!!!\nERROR: Training School create cancelled by user.\n!!!!!"
        next
      end
    else
      puts
    end

    puts 'Starting'

    schools.each do |s|
      User.delete_all(school_id: s.id)
      puts "all usersw= have been deleted"
      (Section.where(school_year_id: s.school_year_id)).each do |sect|
        (SectionOutcome.where section_id: sect.id).each do |so|
          (EvidenceSectionOutcome.where section_outcome_id: so.id).each do |eso|
            EvidenceSectionOutcomeRating.delete_all(evidence_section_outcome_id: eso.id)
            eso.delete
          end
          SectionOutcomeRating.delete_all(section_outcome_id: so.id)
          so.delete
        end
        Evidence.delete_all(section_id: sect.id )
        Enrollment.delete_all(section_id: sect.id )
        TeachingAssignment.delete_all(section_id: sect.id )
        sect.delete
        puts "Section #{sect.name} - #{sect.line_number} has been deleted"
      end

      SchoolYear.delete_all(school_id: s.id)
      (Subject.where(school_id: s.id)).each do |subj|
        SubjectOutcome.delete_all(subject_id: subj.id)
        Subject.delete_all(school_id: s.id)
      end

    end

    puts "Done"

  end # end delete

end
