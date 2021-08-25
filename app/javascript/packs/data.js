require("datatables.net")
require('datatables.net-bs5')
require("datatables.net-bs5/css/dataTables.bootstrap5.min.css")
require("datatables.net-buttons")
require("datatables.net-buttons-bs5")
require("datatables.net-select")
require("datatables.net-select-bs5")


$(document).ready(function() {
  let selected_measurements_datatable = $("#selected_measurements-datatable").DataTable({
    pageLength: 20,
    autoWidth: true,
    searching: false,
    lengthChange: false,
    sDom: 'Br <"H"lf> <"datatable-scroll"t> <"F"ip>',
		deferRender: true,
    buttons: [
      {
        extend: 'selected',
        text: '<i class="fa fa-filter"></i><i class="fa fa-circle"></i> Only keep selected dates',
        action: function ( e, dt, node, config ) {
          var rows = dt.rows( { selected: true } ).count();
          var selected_rows = dt.rows( {selected: true} ).data();
          var selected_ids = [];
          for (let i=0; i < rows; i++) {
            selected_ids.push(selected_rows[i].measurement_id);
          };

          //alert(selected_ids);
          $.ajax({
              type: "get",
              url: '/data/index',
              dataType: 'json',
              data: { manual_table_selection: JSON.stringify(selected_ids) },
              success: function(data) {
                return location.reload();
              },
              error: function(e) {
                alert("Oops! An error occurred, please try again");
                return console.log(e);
              }
          });
        },
        className: 'btn-sm'
      },
      {
        text: '<i class="fa fa-filter"></i><i class="fa fa-circle-o"></i> Disable manual selection filter',
        action: function () {
          $.ajax({
              type: "get",
              url: '/reset_manual_table_selection',
              success: function(data) {
                return location.reload();
              },
              error: function(e) {
                alert("Oops! An error occurred, please try again");
                return console.log(e);
              }
          });
        },
        className: 'btn-sm'
      },
      {
        extend: 'selected',
        text: '<i class="fa fa-line-chart"></i> Calculate calibration of selected dates',
        action: function ( e, dt, node, config ) {
          var rows = dt.rows( { selected: true } ).count();
          var selected_rows = dt.rows( {selected: true} ).data();
          if (selected_rows.length > 1) {
            var values = '';
            for (let i=0; i < rows; i++) {
              values = values + 'ids[]=' + selected_rows[i].c14_measurement_id + '&';
            };
            window.open('/c14_measurements/1/calibrate_multi?' + values, 'Calibration', 'height=800,width=1000,resizable=yes,scrollbars=yes,status=yes');
          } else {
            window.open('/c14_measurements/' + selected_rows[0].c14_measurement_id + '/calibrate', 'Calibration', 'height=800,width=1000,resizable=yes,scrollbars=yes,status=yes');
          }
        },
        className: 'btn-sm'
      },
      {
        extend: 'selected',
        text: '<i class="fa fa-barcode"></i> Calculate sum calibration of selected dates',
        action: function ( e, dt, node, config ) {
          var rows = dt.rows( { selected: true } ).count();
          var selected_rows = dt.rows( {selected: true} ).data();
          var values = '';
          for (let i=0; i < rows; i++) {
            values = values + 'ids[]=' + selected_rows[i].c14_measurement_id + '&';
          };
          window.open('/c14_measurements/1/calibrate_sum?' + values, 'Calibration', 'height=800,width=1000,resizable=yes,scrollbars=yes,status=yes');
        },
        className: 'btn-sm'
      }
    ],
    "processing": true,
    "serverSide": true,
    "ajax": {
      "url": $('#selected_measurements-datatable').data('source')
    },
    "pagingType": "full_numbers",
    "columnDefs": [
      {
       "targets": 0,
       "data": null,
       "searchable": false,
       "defaultContent": '',
       "orderable": false,
       "className": "select-checkbox"
     }
    ],
    "select": {
      "style": "multi",
      "selector": "td:first-child"
    },
    "columns": [
      {"data": "select"},
      {"data": "labnr"},
      {"data": "bp"},
      {"data": "std"},
      {"data": "cal_bp"},
      {"data": "cal_std"},
      {"data": "site"},
      {"data": "period"},
      {"data": "material"},
    ]
    // pagingType is optional, if you want full pagination controls.
    // Check dataTables documentation to learn more about
    // available options.
  });
  
  $('#selectAll').on('click', function() {
	if ($('#selectAll').is(':checked')) {
  	selected_measurements_datatable.rows().select();
  }
  else {
  	selected_measurements_datatable.rows().deselect();
  };
});

});

import 'jquery-ui/ui/widgets/autocomplete.js';
require("../src/autocomplete-rails.js")
