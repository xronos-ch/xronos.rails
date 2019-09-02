// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require best_in_place
//= require jquery_ujs
//= require jquery-ui/widgets/autocomplete
//= require jquery-ui
//= require best_in_place.jquery-ui
//= require autocomplete-rails
//= require activestorage
//= require leaflet
//= require leaflet_lasso
//= require datatables
//= require cocoon
//= require loading_screen
//= require_tree .

// initialize datatables
$(document).ready(function() {
  $("#dttb").dataTable();
});

// special popup window for calibration results
$('a[calibration-popup]').live('click', function(e) {
  window.open( $(this).attr('href'), "Calibration", "height=600,width=900,titlebar=0,resizable=yes,scrollbars=yes,status=yes");
  e.preventDefault();
});
