# all_schools_los_by_subject.rake
# task to delete all learning outcomes for a particular subject (for all schools)
# to run: $ bundle exec rake all_schools_los_by_subject:delete
#

# NOTE: this method deletes all learning outcomes for a subject (for all schools).
# NOTE: This method will only work if there are no section outcomes created for the subject (which would reference these learning outcomes).


namespace :all_schools_los_by_subject do
  desc "Manage Learning Outcomes by Subject for all Schools."

  task delete: :environment do
    # preload a hash with all subjects in the model school
    subjects = Subject.uniq.pluck(:name)
    subjects_by_name = Hash.new
    subjects.each do |s|
      subjects_by_name[s] = s.strip
    end
    # ask the user for a valid subject name, or blank to exit
    subject_name = ''
    while subject_name == ''
      STDOUT.puts 'This will delete all learning outcomes for a subject for all schools.'
      STDOUT.puts 'What subject do you wish to remove the learning outcomes from?'
      STDOUT.puts '(hit enter key to exit this script):'
      answer = STDIN.gets.chomp.strip
      if answer.blank?
        STDOUT.puts 'exiting script'
        subject_name = 'exit'
      else
        ans_subj = subjects_by_name[answer]
        STDOUT.puts "answer: #{answer}, ans_subj: #{ans_subj}"
        if ans_subj == answer
          subject_name = answer
        end
      end
    end

    if subject_name != 'exit'
      STDOUT.puts "Processing subject: ##{subject_name}"
      # check for section outcomes
      sch_with_los = []
      School.all.each do |sch|
        subjs = Subject.where(school_id: sch.id, name: subject_name)
        if subjs.count > 0
          subj = subjs.first
          subjo_ids = SubjectOutcome.where(subject_id: subj.id).pluck(:id)
          sos = SectionOutcome.where(subject_outcome_id: subjo_ids)
          if sos.count > 0
            sch_with_los << sch.acronym
          end
        else
          STDOUT.puts "No matching learning outcomes for sch.id: #{sch.id} - #{subject_name}"
        end
      end # each school
      if sch_with_los.count > 0
        STDOUT.puts "Error: Schools with Sections using learning outcomes from this subject: #{sch_with_los.join(', ')}"
      else
        STDOUT.puts 'Deleting Learning Outcomes!'
        # processing here
        School.all.each do |sch|
          subjs = Subject.where(school_id: sch.id, name: subject_name)
          if subjs.count > 0
            subj = subjs.first
            SubjectOutcome.where(subject_id: subj.id).each do |subjo|
              subjo.destroy
            end
          end
        end # each school
      end
    else
      STDOUT.puts 'Done.'
    end

  end # task :delete

end