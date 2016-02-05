object @section_outcome
attributes :id, :name, :shortened_name
child (:section_outcome_ratings) {
  attributes :id, :student_id, :rating
}
child (:evidence_section_outcomes) do
  attributes :name, :shortened_name, :id
  child (:evidence_section_outcome_ratings) do
    attributes :student_id, :rating, :comment, :flagged
  end
end