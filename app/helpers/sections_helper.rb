# Copyright (c) 2016 21st Century Partnership for STEM Education (21PSTEM)
# see license.txt in this software package
#
module SectionsHelper
    def marking_periods section_outcome
	    return_value = raw ""
	    mp_array = section_outcome.marking_period_array
	    @marking_periods.each do |marking_period|
	      if mp_array.include? marking_period
	        return_value += raw "<span class='include_mp'>#{marking_period}</span> "
	      else
	        return_value += raw "<span class='exclude_mp'>#{marking_period}</span> "
	      end
	    end
	    return_value
    end

	# In SectionController#show, we will not eager load Evidence and their descendant objects, since that will cause
	# all Evidence to be eager loaded even if the learning outcome is minimized.
	# Instead we will use this helper to load evidence section outcomes for each learning outcome. We will also eager load
	# any needed descendant objects.
	# This helper will be called in the view for each maximized learning outcome.
	# We realize that this implementation will result in more requests to the database, but we think it will be faster than eager loading
	# all EvidenceSectionOutcomes and their descendants.
    def get_evidence_section_outcomes section_outcome_id
    	EvidenceSectionOutcome.includes({evidence: :evidence_type},:section).
    	where(section_outcome_id:section_outcome_id,evidences: { active: true }).order('evidences.assignment_date')
    end
    def get_one_evidence_section_outcomes section_outcome_id, evidence_id
      EvidenceSectionOutcome.includes({evidence: :evidence_type},:section).
      where(section_outcome_id:section_outcome_id,evidences: { id: evidence_id, active: true }).order('evidences.assignment_date')
    end
end
