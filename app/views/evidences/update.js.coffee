# deactivate evidence
# check if on tracker page
<% if params[:evidence] %>
  <% if params[:evidence][:active] == 'false' %>
    <% if @errors.length > 0 %>
      $('#breadcrumb-flash-msgs').html("<span class='flash_error'><%= @errors %><span>")
    <% else %>
      eso_row = $("tr[data-evid-id='<%= params[:id] %>']")
      eso_row.hide()
      $('#breadcrumb-flash-msgs').html("<span class='flash_notice'>Removed - '<%= @evidence.name %>'</span>")
    <% end %>
  <% end %>
  <% if params[:evidence][:active] == 'true' %>
    <% if @errors.length > 0 %>
      $('#breadcrumb-flash-msgs').html("<span class='flash_error'><%= @errors %><span>")
    <% else %>
      eso_row = $("#evid_<%= params[:id] %>")
      eso_row.hide()
      $('#breadcrumb-flash-msgs').html("<span class='flash_notice'>Removed - '<%= @evidence.name %>'</span>")
    <% end %>
  <% end %>
<% end %>
