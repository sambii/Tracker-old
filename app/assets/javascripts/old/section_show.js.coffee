# Hide to tool menu when anything outside of that menu is clicked.
$ ->
  $(document).mouseup (e) ->
    container = $("#tools_menu");
    if (container.has(e.target).length == 0)
      container.remove();

markingPeriodDisplay = (marking_period_element) ->
  # Set the marking period buttons to "inactive" styling.
  $("div.mp").css("color","#333")
  $("div.mp").css("font-weight","normal")
  $("div.mp").css("text-decoration","none")
  # Set the selected marking period button to "active" styling
  $(marking_period_element).css("color","#3f0")
  $(marking_period_element).css("font-weight","bold")
  $(marking_period_element).css("text-decoration","underline")
  # Set the selected marking period variable.
  marking_period = $(marking_period_element).html().trim().toString()
  # If "All" is
  if marking_period == "All" or marking_period == 0
    $("#grades_left > table.section_outcome").each () ->
      right_id = $(this).attr('id').replace('left','right')
      $(this).show()
      $("##{right_id}").show()
    marking_period = 0
  else
    $("#grades_left > table.section_outcome").each () ->
      table = this
      right_id = $(this).attr('id').replace('left','right')
      includedMPs = []
      $(this).find(".include_mp").each () ->
        includedMPs.push $(this).html().trim()
      if $.inArray(marking_period, includedMPs) > -1
        $(table).show()
        $("##{right_id}").show()
      else
        $(table).hide()
        $("##{right_id}").hide()

window.colorEvidence = (target) ->
  color = ""
  if $(target).html() != null
    switch $(target).html().trim().charAt(0)
      when "B" then color = "#8bd"
      when "G" then color = "#8db"
      when "R" then color = "#FF9494"
      when "Y" then color = "#e8e679"
      else          color = "#ddd"
  else
    color = "#696969"
  $(target).css('background-color', color)

window.colorSectionOutcome = (target) ->
  color = ""
  if $(target).html() != null
    switch $(target).html().trim()
      when "H" then color = "#368"
      when "P" then color = "#386"
      when "N" then color = "#C23030"
      else          color = "#696969"
  else
    color = "#696969"
  $(target).css('background-color', color)

window.flagEvidence = (target) ->
  $(target).append("<img class='flag' src='/assets/flag.png'>")

scroll_horizontal = () ->
  left        = $("div#grades_left")
  right       = $("div#grades_right")
  right_top   = $(right).offset().top
  scroll_top  = $(window).scrollTop()
  max_scroll  = $(document).height() - $(window).height()
  if scroll_top >= 0 and scroll_top <= max_scroll
    top = right_top - scroll_top
    $(left).css('top', top)

scroll_vertical = () ->
  roster = $("#roster_row")
  left   = -$(window).scrollLeft()
  max_scroll  = $(document).width() - $(window).width()
  if left <= 0 and left >= -max_scroll
    $(roster).css('left', left)

section_outcome_toggle = (target, value) ->
  left_tbody_id = $(target).parents('table').children('tbody').attr('id')
  right_tbody_id = left_tbody_id.replace("left", "right")
  if value == true
    $("##{left_tbody_id}").hide()
    $("##{right_tbody_id}").hide()
  else
    $("##{left_tbody_id}").show()
    $("##{right_tbody_id}").show()

showMenu = (target) ->
  if $("#tools_menu").length
    $("#tools_menu").fadeOut '100', () =>
      $("#tools_menu").remove()
  else
    section_id = $(target).attr('section_id')
    offsets = $(target).offset()
    scroll_top = $(window).scrollTop()
    scroll_left = $(window).scrollLeft()
    div = $("<div id='tools_menu'><ul></ul></div>").css({
      left: offsets.left - scroll_left + 10,
      top: offsets.top - scroll_top + 40
    })
    $(div).children("ul").append("<li><a id='tools_section_attendance' href='/attendances/section_attendance/?section_id=#{section_id}'>Attendance</a></li>")
    $(div).children("ul").append("<li id='tools_new_section_outcome' data_url='sections/#{section_id}/new_section_outcome' data_template='sections/new_section_outcome'>Add Learning Outcome</li>")
    if $("#tools").attr('is_teacher') == "true"
      $(div).children("ul").append("<li id='tools_new_evidence' data_url='sections/#{section_id}/new_evidence teachers/#{CURRENT_USER_ID}' data_template='sections/new_evidence'>Add Evidence</li>")
    else
      $(div).children("ul").append("<li id='tools_new_evidence' data_url='sections/#{section_id}/new_evidence' data_template='sections/new_evidence'>Add Evidence</li>")
    $(div).children("ul").append("<li id='tools_new_enrollment' data_url='sections/#{section_id}/new_enrollment' data_template='sections/new_enrollment'>Add Student</li>")
    $(div).children("ul").append("<li id='tools_restore_evidence' data_template='evidences/restore'>Restore Inactive Evidence</li>")
    $(div).children("ul").append("<li><a id='tools_pdfs' href='/sections/#{section_id}.xlsx'>Export to Excel</a></li>")
    $(div).children("ul").append("<li data_template='sections/pdfs'>Generate Reports</li>")
    $(div)
    $(div).appendTo($('body'))
    cssSandpaper.setBoxShadow(document.getElementById('tools_menu'), "5px 5px 15px #333");
    cssSandpaper.setGradient(document.getElementById('tools_menu'), "-sand-gradient(linear, center top, center bottom, from(#cef), to(#79b))")
    $("#tools_menu").fadeIn '100'
    $("#tools_menu ul li").click () ->
      $("#tools_menu").remove()

displayQuoteBubble = (element) ->
  $(element).css('background-repeat', 'no-repeat')
  $(element).css('background-image', 'url(/assets/comment.png)')

window.section_show_loaded = () ->
  # UJS for batch rating learning outcomes
  $("#batch_rate_outcome").live "click", () ->
    batch_rating_strategy = $("#batch_rating").val()
    unless batch_rating_strategy == ""
      for section_outcome_rating in $("select.section_outcome_rating")
        if batch_rating_strategy == "unrate"
          evidence_rating = ""
          $(section_outcome_rating).val("U")
        else
          if $(section_outcome_rating).val() == "" or $(section_outcome_rating).val() == "U"
            evidence_rating = ""
            tbody = $(section_outcome_rating).parents("tbody")
            if batch_rating_strategy == "top"
              evidence_rating = $($(tbody).children("tr:nth-child(2)").children("td:nth-child(2)").children("div")[0]).html().trim()
            if batch_rating_strategy == "bottom"
              evidence_rating = $($(tbody).children("tr:last-child").children("td:nth-child(2)").children("div")[0]).html().trim()
            switch evidence_rating
              when "B"
                $(section_outcome_rating).val("H")
              when "G"
                $(section_outcome_rating).val("P")
              when "Y"
                $(section_outcome_rating).val("N")
              when "R"
                $(section_outcome_rating).val("N")
  $("#subsections_select").change () ->
    window.location = window.location.pathname + "?subsection=#{$('#subsections_select').val()}"
  # End UJS for batch rating learning outcomes

  # UJS for background images for DIV's with comments.
  $("td.e_r[c='t']").each () ->
    displayQuoteBubble(this);
  # End UJS for background images for DIV's with comments.

  # Filter displayed outcomes by selected marking period.
  if $("div.mp[active=true]").length > 0
    markingPeriodDisplay($("div.mp[active=true]"))
  $("div.mp").click () ->
    marking_period = $(this).html().trim().toString()
    marking_period = 0 if marking_period == "All"
    current_section_id = $("#tools").attr('section_id')
    $.ajax({
      url:  "/sections/#{current_section_id}",
      type: 'put',
      data: {
        source_controller: 'sections',
        source_action: 'show',
        section: { selected_marking_period: marking_period }
      },
      dataType: 'script'
    })
    markingPeriodDisplay(this)
  # End Filter displayed outcomes by selected marking period.

  # Dealing with section tools.
  $("#tools").click () ->
    showMenu(this)
  # End Dealing with section tools.

  # Display indicator for flagged reassessments (@section_outcome_rating.flagged)
  $("div.e_r[f='true']").each () ->
    flagEvidence(this)
  # End Display indicator for flagged reassessments (@section_outcome_rating.flagged)

  # Coloring Evidences and Learning Outcomes
  $("tr.evidence > td.r").each () ->
    colorEvidence(this)
  $("tr.section_outcome > th.r").each () ->
    colorSectionOutcome(this)
  # End Coloring Evidences and Learning Outcomes

  # Scroll the left columns with the right columns.
  if $("div#grades_left").length > 0
    $(window).scroll () ->
      scroll_horizontal()
      scroll_vertical()
  # End Scroll the left columns with the right columns.

  # AJAX for individual section_outcome_ratings
  $(".s_o_r").click (e) ->
    target                = e.currentTarget
    rating_id             = $(target).attr('id').replace("s_o_r_", "")
    student_id            = locateStudent($(target))
    section_outcome_id    = locateRatingTarget($(target))
    student_name          = $("#student_#{student_id}").html().split(",<br>")
    section_outcome_name  = $("#section_outcome_#{section_outcome_id}").html()
    context = {
      id:                   rating_id,
      section_outcome_id:   section_outcome_id,
      student_id:           student_id,
      student_name:         student_name[1] + " " + student_name[0],
      section_outcome_name: section_outcome_name
    }
    if rating_id == "0"
      render_popup Handlebars.templates['section_outcome_ratings/new'](context)
    else
      render_popup Handlebars.templates['section_outcome_ratings/edit'](context)
  # End AJAX for individual section_outcome_ratings

  # AJAX for individual evidence_section_outcome_ratings
  $('.e_r').live 'click', (e) ->
    target = e.currentTarget
    rating_id                   = $(target).attr('id').replace("e_r_", "")
    student_id                  = locateStudent($(target))
    evidence_section_outcome_id = locateRatingTarget($(target))
    student_name                = $("#student_#{student_id}").html().split(",<br>")
    evidence_name               = $("##{$(target).parents("tr").attr('id').replace('right','left')}").find(".evidence_name").html()
    section_outcome_name        = $("##{$(target).parents("tr").attr('id').replace('right','left')}").parents("table").find(".section_outcome_name").html()
    left_id                     = $(target).parents("tr").attr('id').replace('right', 'left')
    if $("##{left_id}").find('.reassessment').length
      reassessment = true
    else
      reassessment = false
    if rating_id == "0"
      context = {
        id:                           rating_id,
        evidence_name:                evidence_name,
        evidence_section_outcome_id:  evidence_section_outcome_id,
        flagged:                      false, # TODO: This is a stub!
        reassessment:                 reassessment,
        section_outcome_name:         section_outcome_name
        student_id:                   student_id,
        student_name:                 student_name[1] + " " + student_name[0]
      }
      render_popup Handlebars.templates['evidence_section_outcome_ratings/new'](context)
    else
      $.get "/e_s_o_r/#{rating_id}.json", (context) ->
        context['student_name']         = student_name[1] + " " + student_name[0]
        context['evidence_name']        = evidence_name
        context['section_outcome_name'] = section_outcome_name
        render_popup Handlebars.templates['evidence_section_outcome_ratings/edit'](context)
  # End AJAX for individual evidence_section_outcome_ratings

  # UJS / Ajax for toggling section_outcome.minimized.
  $(".section_outcome_toggle").each () ->
    if $(this).html() == "+"
      section_outcome_toggle(this, true)

  $(".section_outcome_toggle").click (e) ->
    target = e.currentTarget
    section_outcome_id = $(target).siblings(".section_outcome_name").attr('id').replace('section_outcome_','')
    id = section_outcome_id
    if $(target).html() == "+"
      getEvidencesMarkup(section_outcome_id) if $("#section_outcome_table_left_#{id} > tbody > #empty_evidence_left_#{id}").length > 0 
      value = false
      $(target).html("-")
    else
      value = true
      $(target).html("+")
    section_outcome_toggle(target, value)

    # update the state of the section outcome in the database
    $.ajax {
      url: "/section_outcomes/#{section_outcome_id}.js",
      data: {section_outcome: {minimized: value}},
      type: 'put'
    }
  # End UJS / Ajax for toggling section_outcome.minimized.

  # Set table widths for the right section outcome tables.
  i = $("table#roster").find("th").length
  for target in $(".s_o_right")
    $(target).width(i * 54)

  #start getEvidencesMarkup
  getEvidencesMarkup = (section_outcome_id) ->
    # update the page with evidences after user clicks +
    # the initial load adds an empty_evidence_id div to the dome if the outcome 
    # is minimized.
    id = section_outcome_id
    left = ()-> $.ajax {
        url: "/section_outcomes/#{id}/evidences_left.html",
        cache: true  
    }

    dest = "/section_outcomes/#{id}/evidences_right.html"
    sub  = $('#subsections_select').val()

    #sets the parameter conditionally
    dest += "?subsection=#{sub}" unless typeof sub == 'undefined'

    right = ()-> $.ajax {    
        url: dest,
        cache: true
    }
    
    # use this to tie the loading of the left and right part of the 
    # page together so they both get rendered simultaneously

    $.when(left(),right()).done(
        (leftArgs, rightArgs)->
            $("#empty_evidence_left_#{id}")
                .replaceWith(leftArgs[0]);
            $("#empty_evidence_right_#{id}")
                .replaceWith(rightArgs[0])
            # recolor only partially loaded evidences
            $("#section_outcome_table_right_#{id} tr.evidence > td.r").each () ->
              colorEvidence(this)
            # apply box shadow to some of the elements we just loaded
            p = "#section_outcome_table_left_#{id}" # p is the parent
            $("#{p} .evidence_type,#{p} .evidence_attachments, 
               #{p} .assignment_date,#{p} .evidence_e,#{p} .evidence_section_outcome,#{p} .evidence_x").each () ->
               cssSandpaper.setBoxShadow(this,"2px 2px 3px #035")

        )
    #END getEvidencesMarkup
