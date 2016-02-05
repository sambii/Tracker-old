object @student
attributes :id, :first_name, :last_name
child (@section) do
  attributes :id, :name
  child (:section_outcomes) do |section_outcome|
    attributes :id, :shortened_name
    child (:evidence_section_outcomes) do |evidence|
      attributes :id, :shortened_name
      node (:rating) do |a|
        @evidence_ratings[a.section_outcome_id][a.evidence_id]
      end
    end
  end
end
