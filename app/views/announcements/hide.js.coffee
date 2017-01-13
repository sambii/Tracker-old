$("#announcement_<%= j params[:id] %>").remove()
if $('#announcements ul li').length == 0
  $('#announcements').remove()
