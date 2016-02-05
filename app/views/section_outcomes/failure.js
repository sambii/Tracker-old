<% Rails.logger.error("ERROR - error updating Section Outcome ID: #{@section_outcome.id.to_s}") %>
<% @section_outcome.errors.each do |attr, msg| %>
  <% Rails.logger.error("ERROR - error updating Section Outcome error message: #{msg} - #{msg}") %>
<% end %>
// $('#tracker-comments-students').html("<span class='flash_error'>ERROR updating <%= @section_outcome.id.to_s %> - '<%= @section_outcome.name %>'</span>");
$('#breadcrumb-flash-msgs').html("<%= escape_javascript(render('layouts/messages')) %>")
