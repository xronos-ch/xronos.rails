jQuery(document).ready(function() {
  $('#selected_measurements-datatable').dataTable({
    autoWidth: true,
    pageLength: 20,
    sDom: 'Br <"H"lf> <"datatable-scroll"t> <"F"ip>',
		deferRender: true,
    buttons: [
      {
        text: '<i class="fa fa-plus"></i> Add new date',
        action: function () {
          window.open("/arch_objects/new");
        }
      },
      {
        text: '<i class="fa fa-edit"></i> Edit selected date',
        action: function ( e, dt, node, config ) {
          var rows = dt.rows( { selected: true } ).count();
          var selected_rows = dt.rows( {selected: true} ).data();
          if (selected_rows.length > 1) {
            alert("Only one date can be edited at once.")
          } else {
            window.open('/arch_objects/' + selected_rows[0].arch_object_id + '/edit');
          }
        }
      },
      {
        text: '<i class="fa fa-circle"></i> Select all dates',
        action: function ( e, dt, node, config ) {
          dt.rows().select();
        }
      },
      {
        text: '<i class="fa fa-circle-o"></i> Select no dates',
        action: function ( e, dt, node, config ) {
          dt.rows().deselect();
        }
      },
      {
        extend: 'selected',
        text: '<i class="fa fa-filter"></i><i class="fa fa-circle"> Only keep selected dates',
        action: function ( e, dt, node, config ) {
          var rows = dt.rows( { selected: true } ).count();
          var selected_rows = dt.rows( {selected: true} ).data();
          var selected_ids = [];
          for (i=0; i < rows; i++) {
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
        }
      },
      {
        text: '<i class="fa fa-filter"></i><i class="fa fa-circle-o"> Disable manual selection filter',
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
        }
      },
      {
        extend: 'selected',
        text: '<i class="fa fa-line-chart"></i> Calculate calibration of selected dates',
        action: function ( e, dt, node, config ) {
          var rows = dt.rows( { selected: true } ).count();
          var selected_rows = dt.rows( {selected: true} ).data();
          if (selected_rows.length > 1) {
            var values = '';
            for (i=0; i < rows; i++) {
              values = values + 'ids[]=' + selected_rows[i].c14_measurement_id + '&';
            };
            window.open('/c14_measurements/1/calibrate_multi?' + values, 'Calibration', 'height=800,width=1000,resizable=yes,scrollbars=yes,status=yes');
          } else {
            window.open('/c14_measurements/' + selected_rows[0].c14_measurement_id + '/calibrate', 'Calibration', 'height=800,width=1000,resizable=yes,scrollbars=yes,status=yes');
          }
        }
      },
      {
        extend: 'selected',
        text: '<i class="fa fa-barcode"></i> Calculate sum calibration of selected dates',
        action: function ( e, dt, node, config ) {
          var rows = dt.rows( { selected: true } ).count();
          var selected_rows = dt.rows( {selected: true} ).data();
          var values = '';
          for (i=0; i < rows; i++) {
            values = values + 'ids[]=' + selected_rows[i].c14_measurement_id + '&';
          };
          window.open('/c14_measurements/1/calibrate_sum?' + values, 'Calibration', 'height=800,width=1000,resizable=yes,scrollbars=yes,status=yes');
        }
      },
      {
        text: '<i class="fa fa-download"></i> Download all dates as .csv-file',
        action: function () {
          window.open("?format=csv");
        }
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
      {"data": "source_database"},
      {"data": "labnr"},
      {"data": "bp"},
      {"data": "std"},
      {"data": "cal_bp"},
      {"data": "cal_std"},
      {"data": "delta_c13"},
      {"data": "lab_name"},
      {"data": "site"},
      {"data": "site_phase"},
      {"data": "site_type"},
      {"data": "feature"},
      {"data": "feature_type"},
      {"data": "period"},
      {"data": "typochronological_unit"},
      {"data": "ecochronological_unit"},
      {"data": "material"},
      {"data": "species"},
      {"data": "country"},
      {"data": "lat"},
      {"data": "lng"},
      {"data": "short_ref"},
    ]
    // pagingType is optional, if you want full pagination controls.
    // Check dataTables documentation to learn more about
    // available options.
  });
});

$(document).ready(function() {
  /* Activating Best In Place */
  jQuery(".best_in_place").best_in_place();
});
