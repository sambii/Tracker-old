// not used yet - possibly when page is not refreshed after update.
<% Rails.logger.error("ERROR - error updating Evidence ID: #{@evidence.id.to_s}") %>
<% @evidence.errors.each do |attr, msg| %>
  <% Rails.logger.error("ERROR - error updating Evidence error message: #{msg} - #{msg}") %>
<% end %>
$('#tracker-comments-students').html("<span class='flash_error'>ERROR updating <%= @evidence.id.to_s %> - '<%= @evidence.name %>'</span>");
