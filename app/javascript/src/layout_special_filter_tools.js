$(document).ready(function() {

  var reverse = function (num) {
    return max - num;
  };

  // uncal age range slider
  var $uncal_range = $(".uncal-range-slider"),
    min = -50000,
    max = 0;

  if (typeof gon === 'undefined') {
    uncal_from = -50000;
    uncal_to = 0;
    cal_from = -50000;
    cal_to = 0;
  } else {
    uncal_from = -gon.uncal_age_start;
    uncal_to = -gon.uncal_age_stop;
    cal_from = -gon.cal_age_start;
    cal_to = -gon.cal_age_stop;
  }

  $uncal_range.ionRangeSlider({
    skin: "round",
    type: "double",
    min: min,
    max: max,
    from: uncal_from,
    to: uncal_to,
    step: 100,
    drag_interval: true,
    min_interval: 100,
    prettify: function (num) {
      return reverse(num);
    },
    onChange: function (data) {
      console.dir(data);
      $("#query_uncal_age_start").val(-data.from);
      $("#query_uncal_age_stop").val(-data.to);
    }
  });

  // cal age range slider
  var $cal_range = $(".cal-range-slider"),
    min = -50000,
    max = 0;

  $cal_range.ionRangeSlider({
    skin: "round",
    type: "double",
    min: min,
    max: max,
    from: cal_from,
    to: cal_to,
    step: 100,
    drag_interval: true,
    min_interval: 100,
    prettify: function (num) {
      return reverse(num);
    },
    onChange: function (data) {
      console.dir(data);
      $("#query_cal_age_start").val(-data.from);
      $("#query_cal_age_stop").val(-data.to);
    }
  });

});
