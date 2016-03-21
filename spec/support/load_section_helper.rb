
module LoadSectionHelper
  def load_test_section(section, teacher)

    @server_config = FactoryGirl.create :server_config
    Rails.logger.debug("***** load_test_section")
    @teaching_assignment = FactoryGirl.create :teaching_assignment, teacher: teacher, section: section

    @student   = FactoryGirl.create :student, school: section.school, first_name: 'Student', last_name: '1'
    set_parent_password(@student)
    @enrollment = FactoryGirl.create :enrollment, section: section, student: @student
    @student2   = FactoryGirl.create :student, school: section.school, first_name: 'Student', last_name: '2'
    @enrollment2 = FactoryGirl.create :enrollment, section: section, student: @student2
    @student3   = FactoryGirl.create :student, school: section.school, first_name: 'Student', last_name: '3'
    @enrollment3 = FactoryGirl.create :enrollment, section: section, student: @student3
    @student4   = FactoryGirl.create :student, school: section.school, first_name: 'Student', last_name: '4'
    @enrollment4 = FactoryGirl.create :enrollment, section: section, student: @student4
    @student5   = FactoryGirl.create :student, school: section.school, first_name: 'Student', last_name: '5'
    @enrollment5 = FactoryGirl.create :enrollment, section: section, student: @student5
    @student6   = FactoryGirl.create :student, school: section.school, first_name: 'Student', last_name: '6'
    @enrollment6 = FactoryGirl.create :enrollment, section: section, student: @student6
    @student_unenrolled   = FactoryGirl.create :student, school: section.school, first_name: 'Student', last_name: 'Unenrolled'
    @enrollment_unenrolled = FactoryGirl.create :enrollment, section: section, student: @student_unenrolled
    @student_transferred   = FactoryGirl.create :student, school: section.school, first_name: 'Student', last_name: 'Transferred'
    @enrollment_transferred = FactoryGirl.create :enrollment, section: section, student: @student_transferred
    @student_out   = FactoryGirl.create :student, school: section.school, first_name: 'Student', last_name: 'Out'
    @enrollment_out = FactoryGirl.create :enrollment, section: section, student: @student_out

    @student_new   = FactoryGirl.create :student, school: section.school, first_name: 'Student', last_name: 'New'
    @enrollment_new = FactoryGirl.create :enrollment, section: section, student: @student_new

    # note: not including @student_new
    # note: used to populate ratings, so new student gets no ratings
    @students = {@student.id => @student, @student2.id => @student2, @student3 => @student3, @student4 => @student4, @student5 => @student5, @student6 => @student6, @student_unenrolled => @student_unenrolled, @student_transferred => @student_transferred, @student_out => @student_out}
    # @enrollments = {@enrollment => @enrollment, @enrollment2 => @enrollment2, @enrollment3 => @enrollment3, @enrollment4 => @enrollment4, @enrollment5 => @enrollment5, @enrollment6 => @enrollment6, @enrollment_unenrolled => @enrollment_unenrolled, @enrollment_transferred => @enrollment_transferred, @enrollment_out => @enrollment_out}
    @enrollments = [ @enrollment, @enrollment2, @enrollment3, @enrollment4, @enrollment5, @enrollment6, @enrollment_unenrolled, @enrollment_transferred, @enrollment_out]


    # set of valid ratings for populating the sor and esor records
    val_esors = ["B", "G", "Y", "R", "M", "U"]
    val_sors = ["H", "P", "N", "U"]

    # create subject outcomes for the subject of this section
    @subject_outcomes = Hash.new
    4.times do
      subjo = FactoryGirl.create(:subject_outcome, subject: section.subject)
      @subject_outcomes[subjo.id] = subjo
    end

    # create the section outcomes for the subject outcomes 
    @section_outcomes = Hash.new
    @subject_outcomes.each do |sok, subject_outcome|
      # Random.rand(1000) % 2 == 0 ? m = true : m = false #randomly minimize sections
      secto = FactoryGirl.create(:section_outcome, section: section,
        subject_outcome: subject_outcome, minimized: false) # don't minimize any
      @section_outcomes[secto.id] = secto
    end

    # create six evidences available for this section
    @evidences = Hash.new
    6.times do
      ev = FactoryGirl.create(:evidence, section: section)
      @evidences[ev.id] = ev
    end
    # create a deactivated evidence for this section
    @deact_evidence = FactoryGirl.create(:evidence, section: section, name: 'Deactivated', active: false)
    @evidences[@deact_evidence.id] = @deact_evidence

    # Create Section Outcome Ratings, Evidence Section Outcomes and Evidence Section Outcome Ratings.
    ix = 0
    iy = 0
    # # create an hash (@esos_by_so - by section outcome) of arrays of all of the evidence section outcomes for it
    @sors = Hash.new
    @sors_by_so_s = Hash.new
    @esos = Hash.new
    @esors = Hash.new
    @section_outcomes.each do |kso, so|
      @students.each do |ks, s|
        # Create Section Outcome Rating for all section outcomes for all students.
        sor = FactoryGirl.create :section_outcome_rating, section_outcome: so, student: s, rating: val_sors[ix]
        ix = (ix+1 >= val_sors.length) ? 0 : ix+1
        @sors[sor.id] = sor
        @sors_by_so_s["#{sor.section_outcome_id}:#{s.id}"] = sor
      end
      @evidences.each do |ke, e|
        # Create Evidence Section Outcome for all section outcomes for all evidences.
        eso = FactoryGirl.create :evidence_section_outcome, section_outcome: so, evidence: e
        @esos[eso.id] = eso
        # esor_by_s = Hash.new  # all esors for eso by student
        @students.each do |ks, s|
          # Create Evidence Section Outcome Rating for all Evidence Section Outcomes.
          Rails.logger.debug("++++ create esor for student: #{s.full_name}, #{s.id == @student_unenrolled.id}, #{s.id == @enrollment_unenrolled.student_id}")
          esor = FactoryGirl.create :evidence_section_outcome_rating, evidence_section_outcome: eso, student: s, rating: val_esors[iy]
          iy = (iy+1 >= val_esors.length) ? 0 : iy+1
          @esors[esor.id] = esor
        end
      end
    end

    # missing evidence - deactivated and not deactivated for @student
    @section_outcomes.each do |kso, so|
      eso = FactoryGirl.create :evidence_section_outcome, section_outcome: so, evidence: @deact_evidence
      FactoryGirl.create :evidence_section_outcome_rating, evidence_section_outcome: eso, student: @student, rating: 'M'
    end


    # deactivations from enrollment and from school
    @enrollment_unenrolled.update_attribute(:active, false) # only deactivate enrollment
    @student_transferred.update_attribute(:active, false) # only deactivate student
    @enrollment_out.update_attribute(:active, false) # deactivate both enrollment and student
    @student_out.update_attribute(:active, false) # deactivate both enrollment and student
  end

  def load_multi_schools_sections
    Rails.logger.debug("***** load_multi_schools_sections")
    # two subjects in @school1
    @section1_1 = FactoryGirl.create :section
    @subject1 = @section1_1.subject
    @school1 = @section1_1.school
    @teacher1 = @subject1.subject_manager
    @discipline = @subject1.discipline

    @section1_2 = FactoryGirl.create :section, subject: @subject1
    ta1 = FactoryGirl.create :teaching_assignment, teacher: @teacher1, section: @section1_2
    @section1_3 = FactoryGirl.create :section, subject: @subject1
    ta2 = FactoryGirl.create :teaching_assignment, teacher: @teacher1, section: @section1_3

    @subject2 = FactoryGirl.create :subject, subject_manager: @teacher1
    @section2_1 = FactoryGirl.create :section, subject: @subject2
    @section2_2 = FactoryGirl.create :section, subject: @subject2
    @section2_3 = FactoryGirl.create :section, subject: @subject2
    @discipline2 = @subject2.discipline

    # another subject in @school2
    @section3_1 = FactoryGirl.create :section
    @subject3 = @section3_1.subject
    @school2 = @section3_1.school
    @teacher2 = @subject1.subject_manager
    @section3_2 = FactoryGirl.create :section, subject: @subject3
    @section3_3 = FactoryGirl.create :section, subject: @subject3

  end

  def set_parent_password(student)
    student.parent.password = 'password'
    student.parent.password_confirmation = 'password'
    student.parent.save
  end

  def create_and_load_model_school
    Rails.logger.debug("***** create_and_load_model_school")
    # this needs to be run before any other schools are created, so the ID is 1
    create_model_school
    create_training_school
    model_school_subjects(@model_school)
    model_school_subjects_outcomes(@model_school)
  end

  def create_model_school
    Rails.logger.debug("***** create_model_school")
    # this needs to be run before any other schools are created, so the ID is 1
    @model_school = FactoryGirl.create :school, :arabic, marking_periods:"2", name: 'Model School', acronym: 'MOD'
  end

  def create_training_school
    Rails.logger.debug("***** create_training_school")
    # this needs to be run after create_model_school and before any other schools are created, so the ID is 2
    @training_school = FactoryGirl.create :school, :arabic, marking_periods:"2", name: 'Egyptian Training School', acronym: 'ETS'
  end

  # Create learning outcomes for the Model School Subjects
  # prerequisite: model_school_subjects
  def model_school_subjects(model_school)
    Rails.logger.debug("***** model_school_subjects")
    # note the subject outcome creates below match the spec/fixtures/files/bulk_uploads_los_initial.csv file
    @model_subject_manager = FactoryGirl.create :teacher, school: model_school

    @subj_advisory_1 = FactoryGirl.create :subject, name: 'Advisory 1', subject_manager: @model_subject_manager, school: model_school

    @subj_advisory_2 = FactoryGirl.create :subject, name: 'Advisory 2', subject_manager: @model_subject_manager, school: model_school

    @subj_art_1 = FactoryGirl.create :subject, name: 'Art 1', subject_manager: @model_subject_manager, school: model_school

    @subj_art_2 = FactoryGirl.create :subject, name: 'Art 2', subject_manager: @model_subject_manager, school: model_school

    @subj_art_3 = FactoryGirl.create :subject, name: 'Art 3', subject_manager: @model_subject_manager, school: model_school

    @subj_capstone_1s1 = FactoryGirl.create :subject, name: 'Capstone 1s1', subject_manager: @model_subject_manager, school: model_school

    @subj_capstone_1s2 = FactoryGirl.create :subject, name: 'Capstone 1s2', subject_manager: @model_subject_manager, school: model_school

    @subj_capstone_3s1 = FactoryGirl.create :subject, name: 'Capstone 3s1', subject_manager: @model_subject_manager, school: model_school

  end


  # Create learning outcomes for the Model School Subjects
  # prerequisite: model_school_subjects
  def model_school_subjects_outcomes(model_school)
    Rails.logger.debug("***** model_school_subjects")
    # note the subject outcome creates below match the spec/fixtures/files/bulk_uploads_los_initial.csv file
    @model_subject_manager = FactoryGirl.create :teacher, school: model_school

    # @subj_advisory_1 = FactoryGirl.create :subject, name: 'Advisory 1', subject_manager: @model_subject_manager, school: model_school
    @so_ad_1_01 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_advisory_1, lo_code: 'AD.1.01', description: 'AD.1.01 Original', marking_period: '1'

    # @subj_advisory_2 = FactoryGirl.create :subject, name: 'Advisory 2', subject_manager: @model_subject_manager, school: model_school
    @so_ad_2_01 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_advisory_2, lo_code: 'AD.2.01', description: 'AD.2.01 Original', marking_period: '1'
    @so_ad_2_02 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_advisory_2, lo_code: 'AD.2.02', description: 'AD.2.02 Original', marking_period: '2'

    # @subj_art_1 = FactoryGirl.create :subject, name: 'Art 1', subject_manager: @model_subject_manager, school: model_school
    @so_at_1_01 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_art_1, lo_code: 'AT.1.01', description: 'AT.1.01 Original', marking_period: 'Year Long'
    @so_at_1_02 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_art_1, lo_code: 'AT.1.02', description: 'AT.1.02 Original', marking_period: 'Year Long'
    @so_at_1_03 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_art_1, lo_code: 'AT.1.03', description: 'AT.1.03 Original', marking_period: '1&2'
    @so_at_1_04 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_art_1, lo_code: 'AT.1.04', description: 'AT.1.04 Original', marking_period: '1&2'

    # @subj_art_2 = FactoryGirl.create :subject, name: 'Art 2', subject_manager: @model_subject_manager, school: model_school
    @so_at_2_01 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_art_2, lo_code: 'AT.2.01', description: 'AT.2.01 Original', marking_period: '1'
    @so_at_2_02 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_art_2, lo_code: 'AT.2.02', description: 'AT.2.02 Original', marking_period: '1'
    @so_at_2_03 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_art_2, lo_code: 'AT.2.03', description: 'AT.2.03 Original', marking_period: '2'
    @so_at_2_04 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_art_2, lo_code: 'AT.2.04', description: 'AT.2.04 Original', marking_period: '2'

    # @subj_art_3 = FactoryGirl.create :subject, name: 'Art 3', subject_manager: @model_subject_manager, school: model_school
    @so_at_3_01 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_art_3, lo_code: 'AT.3.01', description: 'AT.3.01 Original', marking_period: '1'
    @so_at_3_02 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_art_3, lo_code: 'AT.3.02', description: 'AT.3.02 Original', marking_period: '1'
    @so_at_3_03 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_art_3, lo_code: 'AT.3.03', description: 'AT.3.03 Original', marking_period: '2'
    @so_at_3_04 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_art_3, lo_code: 'AT.3.04', description: 'AT.3.04 Original', marking_period: '2'

    # @subj_capstone_1s1 = FactoryGirl.create :subject, name: 'Capstone 1s1', subject_manager: @model_subject_manager, school: model_school
    @cp_1_01 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_capstone_1s1, lo_code: 'CP.1.01', description: 'CP.1.01 Original', marking_period: '1'
    @cp_1_02 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_capstone_1s1, lo_code: 'CP.1.02', description: 'CP.1.02 Original', marking_period: '1'
    @cp_1_03 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_capstone_1s1, lo_code: 'CP.1.03', description: 'CP.1.03 Original', marking_period: '1'
    @cp_1_04 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_capstone_1s1, lo_code: 'CP.1.04', description: 'CP.1.04 Original', marking_period: '1'

    # @subj_capstone_1s2 = FactoryGirl.create :subject, name: 'Capstone 1s2', subject_manager: @model_subject_manager, school: model_school
    @cp_1_12 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_capstone_1s2, lo_code: 'CP.1.12', description: 'CP.1.12 Original', marking_period: '2'
    @cp_1_13 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_capstone_1s2, lo_code: 'CP.1.13', description: 'CP.1.13 Original', marking_period: '2'
    @cp_1_14 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_capstone_1s2, lo_code: 'CP.1.14', description: 'CP.1.14 Original', marking_period: '2'
    @cp_1_15 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_capstone_1s2, lo_code: 'CP.1.15', description: 'CP.1.15 Original', marking_period: '2'

    # @subj_capstone_3s1 = FactoryGirl.create :subject, name: 'Capstone 3s1', subject_manager: @model_subject_manager, school: model_school
    @cp_3_01 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_capstone_3s1, lo_code: 'CP.3.01', description: 'CP.3.01 Original', marking_period: '1'
    @cp_3_02 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_capstone_3s1, lo_code: 'CP.3.02', description: 'CP.3.02 Original', marking_period: '1'
    @cp_3_03 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_capstone_3s1, lo_code: 'CP.3.03', description: 'CP.3.03 Original', marking_period: '1'
    @cp_3_04 = FactoryGirl.create :subject_outcome, :arabic, subject: @subj_capstone_3s1, lo_code: 'CP.3.04', description: 'CP.3.04 Original', marking_period: '1'

  end

end

