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
    "columns": [
      {"data": "edit"},
      {"data": "labnr"},
      {"data": "year"},
      {"data": "site"},
      {"data": "site_type"},
      {"data": "lat"},
      {"data": "lng"},
      {"data": "country"},
      {"data": "feature"},
      {"data": "material"},
      {"data": "species"}
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
