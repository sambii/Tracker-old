# tracker_usage_report.rake
# Eventually to be report available in UI

LIVE_SCHOOLS_YEAR = '2016-2017'

namespace :tracker_usage_report do
  desc "Report by school and teacher on activity entered into Tracker."


  task run: :environment do

    sch_yr_ids = SchoolYear.where(name: LIVE_SCHOOLS_YEAR).pluck(:id)
    schools = School.where(school_year_id: sch_yr_ids).each do |sch|
      puts "School: #{sch.name}, #{sch.school_year.name}  run at: #{Time.now}"

      Teacher.where(school_id: sch.id, active: true).each do |t|
        printed_header = false
        t.sections.each do |sec|
          if !printed_header
            puts "  Teacher: #{t.full_name} - #{t.email}"
            puts "    Section                      Evidences    Evidences Rated      LOs Rated"
            printed_header = true
          end
          sec_trimmed_name = (sec.name + ' - ' + sec.line_number).truncate(25, omission: '...').ljust(25, ' ')
          evid_count = 0
          esor_count = 0
          sor_count = 0
          SectionOutcome.where(section_id: sec.id).each do |so|
            EvidenceSectionOutcome.where(section_outcome_id: so.id).each do |eso|
              evid_count += 1
              EvidenceSectionOutcomeRating.where(evidence_section_outcome_id: eso.id).each do |esor|
                esor_count += 1
              end
            end
            SectionOutcomeRating.where(section_outcome_id: so.id).each do |sor|
              sor_count += 1
            end
          end
          evid_trimmed_count = (evid_count.to_s).truncate(5, omission: '...').rjust(5, ' ')
          esor_trimmed_count = (esor_count.to_s).truncate(5, omission: '...').rjust(5, ' ')
          sor_trimmed_count = (sor_count.to_s).truncate(5, omission: '...').rjust(5, ' ')
          puts "    #{sec_trimmed_name}     #{evid_trimmed_count}         #{esor_trimmed_count}              #{sor_trimmed_count}"
        end
      end
    end
    puts "Done"

  end # run

end # tracker_usage_report
