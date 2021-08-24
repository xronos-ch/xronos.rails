/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

// require("bootstrap")

import "stylesheets/application"

import Rails from "@rails/ujs"
//import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"

require("jquery")

import 'bootstrap'

document.addEventListener("turbolinks:load", function() {
    $(function () {
//        $('[data-toggle="tooltip"]').tooltip()
//        $('[data-toggle="popover"]').popover()
    })
})



require('../src/calibrate.js');
import "../src/ion.rangeSlider.js"

import "../src/layout_special_filter_tools.js"

//import '../src/bootstrap.bundle.min';
//import '../src/datatables.js';
//import '../src/dataTables.bootstrap5.min.js';
//import '../src/dataTables.buttons.min.js';
//import '../src/buttons.bootstrap5.min.js';

// special popup window for calibration results
$('a[calibration-popup]').on('click', function(e) {
  window.open( $(this).attr('href'), "Calibration", "height=600,width=900,titlebar=0,resizable=yes,scrollbars=yes,status=yes");
  e.preventDefault();
});


Rails.start()
//Turbolinks.start()
ActiveStorage.start()
