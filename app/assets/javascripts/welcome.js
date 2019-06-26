jQuery(document).ready(function() {
  $('#selected_measurements-datatable').dataTable({
    "sDom": 'r<"H"lf><"datatable-scroll"t><"F"ip>',
    "processing": true,
    "serverSide": true,
    "ajax": {
      "url": $('#selected_measurements-datatable').data('source')
    },
    "pagingType": "full_numbers",
    "columns": [
      {"data": "measurements_id"},
      {"data": "measurements_labnr"},
      {"data": "measurements_year"},
      {"data": "site_name"},
      {"data": "site_lat"},
      {"data": "site_lng"}
    ]
    // pagingType is optional, if you want full pagination controls.
    // Check dataTables documentation to learn more about
    // available options.
  });
});