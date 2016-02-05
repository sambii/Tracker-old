object @enrollment
child (:student) {
  attributes :id, :first_name, :last_name
}
child (:section) {
  attributes :id, :name
  node (:section_outcomes) {
    if params[:rating]
      @enrollment.student.learning_outcomes_by_rating(params[:rating], @enrollment.section_id).map { |a|
        {
          id: a.id,
          name: a.name
        }
      }
    end
  }
}
node (:rating) { long_section_outcome_rating(params[:rating]) }