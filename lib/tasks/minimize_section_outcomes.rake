namespace :section_outcome do
	desc "Minimize section outcomes on the following conditions: \
			1) No child evidence has been updated in the past 7 days \
			2) No rating has been updated on any evidence in the past 7 days"
	task minimize: :environment do
		SectionOutcome.where(minimized:false, active:true).each do |section_outcome|
			in_use = false
			catch :discovery do #acts as a label so we can break out of the nested loop
				section_outcome.evidence_section_outcomes.each do |evidence_section_outcome|
					if evidence_section_outcome.updated_at > 7.days.ago
						in_use=true; throw :discovery
					end
					evidence_section_outcome.evidence_section_outcome_ratings.each do |evidence_section_outcome_rating|
						if evidence_section_outcome_rating.updated_at > 7.days.ago
							in_use = true; throw :discovery 				
						end
					end
				end
			end
			section_outcome.update_attributes(minimized:true) unless in_use
		end
	end
end