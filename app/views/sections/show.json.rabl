object @section
attributes :message, :full_name, :count_ratings
node :students do
  @section.enrollments.alphabetical.map { |a| {
      subsection: a.subsection,
      id: a.student.id,
      last_name: a.student.last_name,
      first_name: a.student.first_name,
      username: a.student.username,
      temporary_password: a.student.temporary_password,
      sign_in_count: a.student.sign_in_count,
      last_sign_in_at: a.student.last_sign_in_at,
      parent: {
        id: a.student.parent.try(:id),
        email: a.student.parent.try(:email),
        subscription_status: a.student.parent.try(:subscription_status),
        username: a.student.parent.try(:username),
        temporary_password: a.student.parent.try(:temporary_password),
        sign_in_count: a.student.parent.try(:sign_in_count),
        last_sign_in_at: a.student.parent.try(:last_sign_in_at)
      },
      not_yet_proficients: a.student.section_outcomes_by_rating("N", @section.id),
      proficients: a.student.section_outcomes_by_rating("P", @section.id),
      high_performances: a.student.section_outcomes_by_rating("H", @section.id)
    }
  }
end

child :section_outcomes do
  attributes :position, :name, :shortened_name, :count_ratings, :id
  node :students, :if => params[:nyp_by_outcome] == "t" do |a, i|
    a.students_by_rating("N")
  end
end
child inactive_evidences: :inactive_evidences do
  attributes :id, :name
end
node :marking_periods do
  @marking_periods
end