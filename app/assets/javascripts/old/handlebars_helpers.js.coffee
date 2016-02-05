Handlebars.registerHelper "count", (array) ->
  return array.length

Handlebars.registerHelper 'set_selected', (a, b, options) ->
  if a == b
    return "selected='true'"
  else
    return ''

Handlebars.registerHelper 'if_current_section', (a, options) ->
  if parseInt(a) == parseInt($("#tools").attr('section_id'))
    return options.fn(this)
  else
    return ""

Handlebars.registerHelper 'is_subject_manager', (options) ->
  if parseInt(this.subject_manager) == parseInt(CURRENT_USER_ID)
    return options.fn(this)
  else
    return ""

Handlebars.registerHelper 'if_not_equal', (a, b, options) ->
  if a != b
    return options.fn(this)
  else
    return ""

Handlebars.registerHelper 'if_equal', (a, b, options) ->
  if a == b
    return options.fn(this)
  else
    return ""

Handlebars.registerHelper 'sum_ratings', (h, p, n) ->
  sum = h + p + n
  sum

Handlebars.registerHelper 'evidence_rating', (ratings_node, student_id) ->
  result = "<td></td><td></td>"
  unless ratings_node == undefined
    for node in ratings_node
      result = "<td>#{node.rating}</td><td>#{node.comment}</td>" if node.student_id == student_id
  new Handlebars.SafeString result

Handlebars.registerHelper 'checked', (boolean) ->
  if boolean
    result = "checked=\"checked\""
  else
    result = ""
  new Handlebars.SafeString result

# Register current section ID
Handlebars.registerHelper 'current_section_id', () ->
  result = $('#tools').attr('section_id')
  new Handlebars.SafeString result

# Register the current controller and action as a Handlebars Helper.
Handlebars.registerHelper 'current_controller_action', () ->
  controller = $("#current_controller").html()
  action     = $("#current_action").html()
  result     = "<input name='source_controller' type='hidden' value='#{controller}'>"
  result    += "<input name='source_action' type='hidden' value='#{action}'>"
  new Handlebars.SafeString result

  # Register the Authenticity Token as a Handlebars Helper.
Handlebars.registerHelper 'authenticity_token', () ->
  result = "<input name='authenticity_token' type='hidden' value='#{AUTH_TOKEN}'>"
  new Handlebars.SafeString result

# Handlebars Helper to render the students' information for rating evidence.
Handlebars.registerHelper 'evidence_student_table', (context) ->
  result = ""
  students = context.students
  evidence_section_outcomes = context.evidence_section_outcomes
  subsection_id = $("#tools").attr('subsection_id')
  k = 0
  for student, j in students

    if parseInt(subsection_id) == 0 or parseInt(student.subsection) == parseInt(subsection_id)
      result += "<table>" if result.length == 0
      result += "<tbody><tr><th colspan=3 style='background-color: #035; color: white;'><b>#{student.last_name}, #{student.first_name}</b></th></tr>"
      for evidence_section_outcome, i in evidence_section_outcomes
        # Initialize values for the rating if absent!
        if student.ratings[evidence_section_outcome.id] == undefined
          rating = {id: undefined, rating: "", comment: ""}
        else
          rating = student.ratings[evidence_section_outcome.id]
        if rating.comment.length > 0
          comment_value = "value=\"#{rating.comment}\""
        else
          comment_value = ""
        result += "<tr><td style='font-size: 0.9em'>#{evidence_section_outcome.section_outcome_name}</td>"
        result += "<td><input name='evidence[evidence_section_outcomes_attributes][#{i}][id]' value='#{evidence_section_outcome.id}' type='hidden'>"
        result += "<input name='evidence[evidence_section_outcomes_attributes][#{i}][section_outcome_id]' value='#{evidence_section_outcome.section_outcome_id}' type='hidden'>"
        unless rating.id == undefined
          result += "<input name='evidence[evidence_section_outcomes_attributes][#{i}][evidence_section_outcome_ratings_attributes][#{j}][id]' value='#{rating.id}' type='hidden'>"
        result +=   "<input name='evidence[evidence_section_outcomes_attributes][#{i}][evidence_section_outcome_ratings_attributes][#{j}][student_id]' value='#{student.id}' type='hidden'>"
        result +=   "<input #{'copy-down-target="true" copy-down-selector="input.evidence_rating" copy-down-container="tbody"' if i == 0} class='evidence_rating' name='evidence[evidence_section_outcomes_attributes][#{i}][evidence_section_outcome_ratings_attributes][#{j}][rating]' id='rating_#{k}' value='#{rating.rating}' size=2 autcomplete='off'></td>"
        result +=   "<td><input name='evidence[evidence_section_outcomes_attributes][#{i}][evidence_section_outcome_ratings_attributes][#{j}][comment]' id='comment_#{k}' value='#{rating.comment}' size=20>"
        result +=   "</td></tr>"
        k += 1
      result += "</tbody>"
  result += "</table>" if result.length > 0
  new Handlebars.SafeString result

selected = (rating, letter) ->
  if rating == letter
    return " selected = 'true'"
  ''

Handlebars.registerHelper 'section_outcome_student_table', () ->
  # Init some vars...
  result = ""
  students = this.students
  evidences = if this.evidence_section_outcomes == undefined then [] else this.evidence_section_outcomes
  section_outcome_ratings = if this.section_outcome_ratings == undefined then [] else this.section_outcome_ratings
  subsection_id = $("#tools").attr('subsection_id')
  # Build result
  # Loop through students
  for student, i in students
    if parseInt(student.subsection) == parseInt(subsection_id) || subsection_id == "0"
      rating = ''
      result += "<table class='rate_section_outcome'>" if result.length == 0
      result += "<tbody><tr><td class='student'>#{student.last_name} #{student.first_name}</td><td colspan=2 class='student'>"
      result += "<input name='section_outcome[section_outcome_ratings_attributes][#{i}][student_id]' value='#{student.id}' type='hidden'>"
      for section_outcome_rating in section_outcome_ratings
        if section_outcome_rating.student_id == student.id
          rating = section_outcome_rating.rating
          result +=" <input name='section_outcome[section_outcome_ratings_attributes][#{i}][id]' value='#{section_outcome_rating.id}' type='hidden'>"
      result += "<select class='section_outcome_rating' name='section_outcome[section_outcome_ratings_attributes][#{i}][rating]'>
                    <option#{selected(rating, '')}></option>
                    <option value='H'#{selected(rating, 'H')}>High Performance</option>
                    <option value='P'#{selected(rating, 'P')}>Proficient</option>
                    <option value='N'#{selected(rating, 'N')}>Not Yet Proficient</option>
                    <option value='U'#{selected(rating, 'U')}>Unrated</option>
                   </select></td></tr>"
      # Loop through evidences to build the ratings table.
      for evidence, j in evidences
        bottom = if j == evidences.length - 1 then " bottom" else ""
        result += "<tr><td class='evidence#{bottom}'>#{evidence.name}</td>"
        evidence.evidence_section_outcome_ratings = [] if evidence.evidence_section_outcome_ratings == undefined
        z = ""
        for evidence_rating, k in evidence.evidence_section_outcome_ratings
          z = "<td class='rating_cell#{bottom}'><div class='rating_div'>#{evidence_rating.rating}</div></td><td class='comment#{bottom}'>#{evidence_rating.comment}</td>" if evidence_rating.student_id == student.id
          z = "<td class='rating_cell#{bottom}'><div class='rating_div'></div></td><td class='comment#{bottom}'></td>" if z == "" and k == evidence.evidence_section_outcome_ratings.length - 1
        result += z

      result += "</tr></tbody>"
  result += "</table>" if result.length > 0
  new Handlebars.SafeString result