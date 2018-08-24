# all_schools_los_by_subject.rake
# task to delete all learning outcomes for a particular subject (for every school except the Training school)
# to run: $ bundle exec rake all_schools_los_by_subject:delete
#

# NOTE: this method deletes all learning outcomes for a subject (for every school except the Training school).
# NOTE: Only subjects in the Model School will be listed.
# NOTE: This method will only work if there are no section outcomes created for the subject (which would reference these learning outcomes).
namespace :all_schools_los_by_subject do

  desc "Delete all Learning Outcomes in the Schools for a selected Subject (except the Training School)."
  task delete: :environment do

    # get model and training school ids
    sch_mods = School.where(acronym: 'MOD', id: 1)
    raise "Error: missing Model School" if sch_mods.count != 1
    sch_mod = sch_mods.first
    STDOUT.puts "Model School: #{sch_mod.name}"
    sch_trains = School.where(acronym: 'ETH', id: 2)
    raise "Error: missing Training School" if sch_trains.count != 1
    sch_train = sch_trains.first
    STDOUT.puts "Training School: #{sch_train.name}"

    # preload a hash with all subjects in the model school
    # subjects = Subject.uniq.pluck(:name)
    subjects = Subject.where(school_id: sch_mod.id)
    subjects_by_name = Hash.new
    subjects.each do |s|
      subjects_by_name[s.name] = s
    end

    # ask the user for a valid subject name, or blank to exit
    subject_name = ''
    while subject_name == ''
      STDOUT.puts 'This will delete all Learning Outcomes in the Schools for a Subject.'
      STDOUT.puts 'What subject do you wish to remove the learning outcomes from?'
      STDOUT.puts '(hit enter key to exit this script):'
      answer = STDIN.gets.chomp.strip
      if answer.blank?
        STDOUT.puts 'exiting script'
        subject_name = 'exit'
      else
        ans_subj = subjects_by_name[answer].name
        STDOUT.puts "answer: #{answer}, ans_subj: #{ans_subj}"
        if ans_subj == answer
          subject_name = answer
        end
      end
    end

    if subject_name != 'exit'
      STDOUT.puts "Processing subject: #{subject_name}"
      # check for section outcomes in the schools (except the Model and Training Schools).
      # if section outcomes exist, then we know that some sections were created, and the Learning Outcome has been assigned to some sections, so we do not want to delete them.
      sch_with_los = []
      School.where("id NOT IN (?)", [sch_mod.id, sch_train.id]).each do |sch|
        STDOUT.puts "Checking school: #{sch.acronym} - #{sch.name}"
        subjs = Subject.where(school_id: sch.id, name: subject_name)
        if subjs.count > 0
          subj = subjs.first
          subjo_ids = SubjectOutcome.where(subject_id: subj.id).pluck(:id)
          # get all section outcomes for this subject outcome
          sos = SectionOutcome.where(subject_outcome_id: subjo_ids)
          if sos.count > 0
            # There are section outcomes for this Subject Outcome!
            sch_with_los << sch.acronym
          end
        else
          STDOUT.puts "Warning: No matching Subject (#{subject_name}) for sch.id: #{sch.acronym} - #{sch.name}"
        end
      end # each school
      if sch_with_los.count > 0
        STDOUT.puts "Fatal Error: There are Sections using learning outcomes from this subject in the following schools: #{sch_with_los.join(', ')}"
      else
        STDOUT.puts 'Deleting Learning Outcomes!'
        # delete Los for the schools (except the training school)
        School.where("id NOT IN (?)", [sch_train.id]).each do |sch|
          STDOUT.puts "About to process school: #{sch.acronym} - #{sch.name}"
          subjs = Subject.where(school_id: sch.id, name: subject_name)
          if subjs.count > 0
            subj = subjs.first
            destroy_count = 0
            SubjectOutcome.where(subject_id: subj.id).each do |subjo|
              subjo.destroy
              destroy_count += 1
            end
            STDOUT.puts "Deleted #{destroy_count} Learning Outcomes in school: #{sch.acronym} - #{sch.name}"
          end
        end # each school
      end
    else
      STDOUT.puts 'Done.'
    end

  end # task :delete

  desc "Copy all Learning Outcomes from Model School to all other Schools for a Subject."
  task copy: :environment do

    # get model and training school ids
    sch_mods = School.where(acronym: 'MOD', id: 1)
    raise "Error: missing Model School" if sch_mods.count != 1
    sch_mod = sch_mods.first
    STDOUT.puts "Model School: #{sch_mod.name}"
    sch_trains = School.where(acronym: 'ETH', id: 2)
    raise "Error: missing Training School" if sch_trains.count != 1
    sch_train = sch_trains.first
    STDOUT.puts "Training School: #{sch_train.name}"

    # preload a hash with all subjects in the model school
    # subjects = Subject.uniq.pluck(:name)
    subjects = Subject.where(school_id: sch_mod.id)
    subjects_by_name = Hash.new
    subjects.each do |s|
      subjects_by_name[s.name] = s
    end

    # ask the user for a valid subject name, or blank to exit
    subject_name = ''
    while subject_name == ''
      STDOUT.puts 'This will copy all Learning Outcomes from Model School to the other Schools for a Subject.'
      STDOUT.puts 'What subject do you wish to copy the learning outcomes from?'
      STDOUT.puts '(hit enter key to exit this script):'
      answer = STDIN.gets.chomp.strip
      if answer.blank?
        STDOUT.puts 'exiting script'
        subject_name = 'exit'
      else
        ans_subj = subjects_by_name[answer].name
        STDOUT.puts "answer: #{answer}, ans_subj: #{ans_subj}"
        if ans_subj == answer
          subject_name = answer
        else
          STDOUT.puts "cannot find subject with the name: #{answer}"
        end
      end
    end

    if subject_name != 'exit'
      STDOUT.puts "Processing subject: #{subject_name}"
      # check for subject outcomes in the schools (except the Training School).
      # If subject outcomes already exist, we do not want to copy them in from the Model school
      sch_with_los = []
      subjos = []
      School.where("id NOT IN (?)", [sch_train.id]).each do |sch|
        subjs = Subject.where(school_id: sch.id, name: subject_name)
        if subjs.count > 0
          subj = subjs.first
          # check to see if there are any subject outcomes for this subject in this school
          sch_subjos = SubjectOutcome.where(subject_id: subj.id)
          subjos.concat sch_subjos
          if sch_subjos.count > 0
            sch_with_los << sch.acronym
          end
        else
          STDOUT.puts "Warning: No matching Subject (#{subject_name}) for sch.id: #{sch.acronym} - #{sch.name}"
        end
      end # each school
      STDOUT.puts "subject outcomes to copy count: #{subjos.count}"
      if !sch_with_los.include?('MOD')
        STDOUT.puts "Error: No Subject Outcomes to copy in the Model School."
      elsif sch_with_los.count > 1
        STDOUT.puts "Error: Subject Outcomes already exists in other schools."
      else
        # only model school subject outcomes should exist in subjos array - use them to copy to other schools.
        School.where("id NOT IN (?)", [sch_mod.id, sch_train.id]).each do |sch|
          subjs = Subject.where(school_id: sch.id, name: subject_name)
          if subjs.count > 0
            subj = subjs.first
            copy_count = 0
            subjos.each do |subjo|
              new_subjo = subjo.clone
              new_subjo.subject_id = subj.id
              new_subjo.save
              copy_count += 1
            end
            STDOUT.puts "Copied #{copy_count} Learning Outcomes to school: #{sch.acronym} - #{sch.name}"
          end
        end # each school
      end
    else
      STDOUT.puts 'Done.'
    end

  end # task :copy

end