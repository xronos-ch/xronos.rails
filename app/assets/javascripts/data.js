jQuery(document).ready(function() {
  $('#selected_measurements-datatable').dataTable({
    "autoWidth": true,
    "sDom": 'Br<"H"lf><"datatable-scroll"t><"F"ip>',
    "buttons": [
      {
        extend: 'selected',
        text: 'Only show selected',
        action: function ( e, dt, node, config ) {
          var rows = dt.rows( { selected: true } ).count();
          var selected_rows = dt.rows( {selected: true} ).data();
          var selected_ids = [];
          for (i=0; i < rows; i++) {
            selected_ids.push(selected_rows[i].measurement_id);
          };

          alert(selected_ids);

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
        text: 'Disable selection',
        action: function () {
          $.ajax({
              type: "get",
              url: '/data/index',
              dataType: 'json',
              data: { turn_off_manual_table_selection: JSON.stringify(true) },
              success: function(data) {
                return location.reload();
              },
              error: function(e) {
                alert("Oops! An error occurred, please try again");
                return console.log(e);
              }
          });
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
      {"data": "edit"},
      {"data": "calibrate"},
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
