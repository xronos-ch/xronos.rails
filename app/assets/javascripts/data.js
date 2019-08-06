jQuery(document).ready(function() {
  $('#selected_measurements-datatable').dataTable({
    "autoWidth": true,
    "sDom": 'r<"H"lf><"datatable-scroll"t><"F"ip>',
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
      {"data": "site"},
      {"data": "site_type"},
      {"data": "feature"},
      {"data": "lat"},
      {"data": "lng"},
      {"data": "country"},
      {"data": "material"},
      {"data": "species"}
    ],
    "dom": 'Bfrtip',
    "buttons": [
      {
        "text": 'Get selected data',
        "action": function () {
          var count = table.rows( { selected: true } ).count();
          alert(count);
        }
      }
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
