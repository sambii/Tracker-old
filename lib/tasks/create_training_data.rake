namespace :training_data do
	desc "Create training data"

	# BUSINESS LOGIC
	# 30 Generic Teacher Accounts for each school (Teacher 1, Teacher 2, Teacher 3, etc.)
	# Each teacher should have two sections (Section 1, Section 2)
	# Each sections should have at 15 students (Last Name, First Name)
	# Each section should have at least 10 learning outcomes
	# 5 of learning outcomes should already be added to the section
    # 	Each of the 5 LOs should have 4 pieces of evidence
    #   	Of the five,  Two of the LOs and the supporting evidence should be rated
    #       	Of the five,  the remaining Three of the LOs should NOT be rated
    #           	Of the three not rated LOs, Two of the LOs supporting evidence should be rated
    #               	Of the three not rated LOs, the one remaining LOs supporting evidence should NOT be rated


    #PRE-REQ: An Evidence Type named "Homework" must exist in the system else this script will fail
	task create: :environment do

		puts "create schools, school year and admins"

		school_acronym = Faker::Lorem.characters(3).upcase
		school = School.create!(
		  name: "#{school_acronym} Training School",
		  acronym: school_acronym,
		  street_address: "1 Stub Lane",
		  city: "Conshohocken",
		  state: "PA",
		  zip_code: "19428",
		  marking_periods: 4,
		)

		school_year = SchoolYear.create!(
		  name: "#{school_acronym} 2012->2013",
		  school_id: school.id,
		  starts_at: DateTime.parse("2012-09-01 12:30 PM"),
		  ends_at: DateTime.parse("2013-06-20 12:30 PM")
		)

		puts "school_id #{school.id}"
		puts "school_year #{school_year.id}"
		school.update_attributes(school_year_id:school_year.id)
		puts "school year id #{school.school_year_id}"
		puts "school_id #{school.id}"
		puts "school_acronym #{school_acronym}"

		school_admin = SchoolAdministrator.create!(
		  username: "#{school_acronym}_school_admin",
		  first_name: "SchoolAdmin_FirstName",
		  last_name: "SchoolAdmin_LastName",
		  email: Faker::Internet.safe_email,
		  school_id: school.id,
		  password: "password",
		  password_confirmation: "password"
		)

		puts "school admin created"

		Counselor.create!(
		    username: "#{school_acronym}_counselor",
		    first_name: "Counselor_FirstName",
		    last_name: "Counselor_LastName",
		    email: Faker::Internet.safe_email,
		    school_id: school.id,
		    password: "password",
		    password_confirmation: "password"
		)

		puts "create 75 teachers"
		teachers = []
		75.times do |n|
			teachers << Teacher.create!(
			  username: "teacher#{n+1}",
			  first_name: "FirstName #{n+1}",
			  last_name: "LastName #{n+1}",
			  email: Faker::Internet.safe_email,
			  school_id: school.id,
			  password: "password",
			  password_confirmation: "password"
			)
		end

		puts "create a discipline"
		discipline = Discipline.create!(
		  name: "#{school_acronym} Discipline"
		)

		puts "create 5 subjects"
		subjects=[]
		5.times do |n|
			subjects << Subject.create!(
			  name: "Subject #{n+1}",
			  discipline_id: discipline.id,
			  school_id: school.id,
			  subject_manager_id: school_admin.id
			)
		end

		puts "create two sections per teacher and assign them to it"
		sections = []

		# each teacher gets one of 5 subjects (loop increments for each teacher)
		# each teacher gets two sections for that subject
		subj_ix = 0

		teachers.each_with_index do |teacher, ix|
			# create first section for a teacher (with teacher seq number in name)
			section = Section.create!(
			  line_number: "#{'%02d' % ix}1",
			  subject_id: subjects[subj_ix].id,
			  school_year_id: school.school_year_id,
			  message: "Listen here!"
			)
			# assign the teacher to it
			TeachingAssignment.create!(
			  teacher_id: teacher.id,
			  section_id: section.id
			)
			# add the new section to the sections array
			sections << section

			# create the second section for the teacher (with teacher seq number in name)
			section = Section.create!(
			  line_number: "#{'%02d' % ix}2",
			  subject_id: subjects[subj_ix].id,
			  school_year_id: school.school_year_id,
			  message: "Listen here!"
			)
			# assign the teacher to it
			TeachingAssignment.create!(
			  teacher_id: teacher.id,
			  section_id: section.id
			)
			# add the new section to the sections array
			sections << section

			# go to next subject (or back to first)
			subj_ix = (subj_ix < 4) ? subj_ix + 1 : 0
		end

		puts "create 598 students"
		students = []
		598.times do |n|
		  my_username = "Student #{n}"
		  s = Student.create!(
		    username: my_username,
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

		# pointer to the last student assigned
		stud_ix = 0

		puts "assign the next 15 new students to each section"
		# sections.each do |section|
	 #    15.times do |n|

		# 	  # enroll the student into the class
		# 	  Enrollment.create!(
		# 	    student_id: students[stud_ix].id,
		# 	    section_id: section.id,
		# 	    student_grade_level: students[stud_ix].grade_level
		# 	  )

		# 		# go to next student (or back to first)
		# 		stud_ix = (stud_ix < 597) ? stud_ix + 1 : 0
	 #    end
		# end
		sect_ix = 0
		4.times do |n|
			students.each do |s|
			  Enrollment.create!(
			    student_id: s.id,
			    section_id: sections[sect_ix].id,
			    student_grade_level: s.grade_level
			  )
			  sect_ix = (sect_ix < (sections.count - 1)) ? sect_ix + 1 : 0
			end
		end


		puts "create 10 subject outcomes per subject"
		subject_outcomes = []
		subjects.each do |subject|
			10.times do |n|
			   s = SubjectOutcome.create!(
			     name: "Sample Learning Outcome #{n+1}",
			     subject_id: subject.id,
			   )
			   subject_outcomes << s
			end
		end

		section_outcomes = []

		puts "assign first 5 subject outcomes for a subject to each section"
		rander = Random.new(Random.new_seed) # for LO marking period assignment bitmask
		sections.each do |section|
			n=0
			subject_outcomes.each do |subject_outcome|
				if n < 5
					if section.subject_id == subject_outcome.subject_id
						section_outcomes << SectionOutcome.create!(
					    subject_outcome_id: subject_outcome.id,
					    section_id: section.id,
					    marking_period: rander.rand(1..15), # Bitmask!
					    active: true,
					    minimized: false
						)
						n = n + 1
					end
				end
			end
		end

		puts "make sure all Evidence Types exist"
		evidence_types = ["Homework", "In-Class", "Quiz", "Test"]
		evidence_type_ids = []

		# load up evidence_type_ids with existing or new IDs of all evidence types
		evidence_types.each_with_index do |ev, i|
			db_evidence_types = EvidenceType.where(name: ev)
			if db_evidence_types.count > 0
				evidence_type_ids[i] = db_evidence_types.first.id
			else
				evidence_type = EvidenceType.create(name: ev)
				evidence_type_ids[i] = evidence_type.id
			end
			puts "Evidence Type #{evidence_types[i]} has ID of #{evidence_type_ids[i]}"
		end

		puts "Create 4 pieces of evidence per Section Outcome"
		sections.each do |section|
			section.section_outcomes.each do |section_outcome|
				# evidences = []
		  	4.times do |n|
		  		# create the evidence record
		  		e = Evidence.create!(
		    		section_id: section.id,
		    		name: "Evidence #{n+1}",
				    description: "Basically, evidences are homework assignments, tests, quizzes, etc.",
				    assignment_date: DateTime.now,
				    active: true,
				    evidence_type_id: evidence_type_ids[n],
				    reassessment: false
		  		)
		  		# evidences << e
		  		# create the evidence_section_outcome record
					EvidenceSectionOutcome.create!(
						evidence_id: e.id,
						section_outcome_id: section_outcome.id
					)
				end
			end
		end

		so_ratings = ["N","P","H"]
		e_ratings  = ["R","G","Y","B"]

		puts "set ratings for LOs"
		sections.each do |section|
			section.section_outcomes.first(2).each do |section_outcome|
				section.students.each do |student|
					SectionOutcomeRating.create!(
			 	      rating: so_ratings[Random.rand(3)],
			 	      student_id: student.id,
			 	      section_outcome_id: section_outcome.id
			 	    )

				    section_outcome.evidence_section_outcomes.each do |eso|
				    	e_rating = EvidenceSectionOutcomeRating.create!(
	 	      				rating: e_ratings[Random.rand(4)],
	 	      				student_id: student.id,
	 	      				evidence_section_outcome_id: eso.id,
	 	      				comment: ""
	 	    			)
				    end
			 	end
			end

			section.section_outcomes.last(2).each do |section_outcome|
				section.students.each do |student|
					section_outcome.evidence_section_outcomes.each do |eso|
				    	e_rating = EvidenceSectionOutcomeRating.create!(
	 	      				rating: e_ratings[Random.rand(4)],
	 	      				student_id: student.id,
	 	      				evidence_section_outcome_id: eso.id,
	 	      				comment: ""
	 	    			)
				    end
				end
			end

			# print section ID for each section as it is completed
			print "#{section.id}, "
			$stdout.flush
		end
		puts ""
		puts "Done"
	end
end