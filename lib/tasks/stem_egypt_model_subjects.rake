# stem_egypt_model_subjects.rake
# to populate a server's disciplines and load model school with subjects
# to delete: $ bundle exec rake stem_egypt_model_subjects:populate
#

# NOTE: do not call tasks within tasks without changing the error handling to use 'raise' not 'next'


namespace :stem_egypt_model_subjects do
  desc "Create initial set of model school subjects."

  task populate: :environment do
    discips = [
      {dname: 'Administration', dsubjs: [
        'Advisory 1',
        'Advisory 2',
        'Library 1',
        'Library 2',
        'Library 3'
      ]},
      {dname: 'Capstones', dsubjs: [
        'Capstone 1s1',
        'Capstone 1s2',
        'Capstone 2s1',
        'Capstone 2s2',
        'Capstone 3s1'
      ]},
      {dname: 'Creative Arts', dsubjs: [
        'Art 1',
        'Art 2',
        'Art 3',
        'Music 1',
        'Music 2',
        'Music 3'
      ]},
      {dname: 'Linguistics', dsubjs: [
        'Arabic 1',
        'Arabic 2',
        'Arabic 3',
        'English 1',
        'English 2',
        'English 3',
        'French 1',
        'French 2',
        'French 3',
        'German 1',
        'German 2',
        'German 3'
      ]},
      {dname: 'Mathematics', dsubjs: [
        'Math 1',
        'Math 2',
        'Math 3',
        'Mechanics 1',
        'Mechanics 2',
        'Mechanics 3',
        'Statistics 3'
      ]},
      {dname: 'Personal Health', dsubjs: [
        'Physical Education Boys 1',
        'Physical Education Boys 2',
        'Physical Education Boys 3',
        'Physical Education Girls 1',
        'Physical Education Girls 2',
        'Physical Education Girls 3'
      ]},
      {dname: 'Science', dsubjs: [
        'Biology 1',
        'Biology 2',
        'Biology 3',
        'Chemistry 1',
        'Chemistry 2',
        'Chemistry 3',
        'Earth Science 1',
        'Earth Science 2',
        'Earth Science 3',
        'Physics 1',
        'Physics 2',
        'Physics 3'
      ]},
      {dname: 'Social and Life Sciences', dsubjs: [
        'Citizenship 1',
        'Citizenship 2',
        'Citizenship 3',
        'Home Economics 1',
        'Home Economics 2',
        'Home Economics 3',
        'Social Studies 1'
      ]},
      {dname: 'Technology', dsubjs: [
        'Computer Science 1',
        'Computer Science 2',
        'Computer Science 3',
        'Fab Lab 1'
      ]}
    ]

    # get model school
    schools = School.where(acronym: 'MOD')
    if schools.count > 0
      school = schools.first
    else
      puts "!!!!!\nERROR: Cannot find model school.\n!!!!!"
      next
    end

    # check number of subjects, remove if any (and confirmed)
    subjs = Subject.where(school_id: school.id)
    if subjs.count > 0
      input = ''
      STDOUT.puts "Subjects in Model School already exist.  If you wish to recreate the subjects, hit enter to continue"
      input = STDIN.gets.chomp
      if input != ""
        puts "!!!!!\nERROR: Training School create cancelled by user.\n!!!!!"
        next
      end
      subjs.each do |s|
        s.destroy
      end
    end

    discips.each do |discip|
      STDOUT.puts "Discipline: #{discip[:dname]}"

      # add discipline if not there already
      match_ds = Discipline.where(name: discip[:dname])
      if match_ds.count > 0
        disc = match_ds.first
      else
        disc = Discipline.create(name: discip[:dname])
      end
      discip[:dsubjs].each do |sname|
        # add subject to model school
        STDOUT.puts "  #{sname}"
        subj = Subject.create(name: sname, school_id: school.id, discipline_id: disc.id)
      end
    end

  end

end