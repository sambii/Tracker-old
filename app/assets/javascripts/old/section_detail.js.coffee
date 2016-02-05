$ ->
  $(".student_evidence_rating").each () ->
    colorEvidence(this)

  $("#filter_select").change () ->
    switch this.value
      when "all"
        $("tbody.section_outcome").show()
      when "nyp"
        for element in $("th.student_section_outcome_rating > div")
          if $(element).html().trim() == "Not Yet Proficient"
            $(element).parents("tbody").show()
          else
            $(element).parents("tbody").hide()
      when "mp1"
        evaluateMP("1")
      when "mp2"
        evaluateMP("2")
      when "mp3"
        evaluateMP("3")
      when "mp4"
        evaluateMP("4")
      when "mp5"
        evaluateMP("5")
      when "mp6"
        evaluateMP("6")

  $("#toggle_evidence").change () ->
    if this.checked == true
      $("tr.evidence").hide()
    else
      $("tr.evidence").show()

evaluateMP = (mp) ->
  for section_outcome in $("tbody.section_outcome")
    if $(section_outcome).attr("mps").indexOf(mp) != -1
      $(section_outcome).show()
    else
      $(section_outcome).hide()

colorEvidence = (target) ->
  color = ""
  switch $(target).find("div").html().trim().charAt(0)
    when "B" then color = "#8bd"
    when "G" then color = "#8db"
    when "R" then color = "#FF9494"
    when "Y" then color = "#e8e679"
    else          color = "#ddd"
  $(target).css('background-color', color)