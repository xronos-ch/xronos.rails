$(document).ready(function() {

  var reverse = function (num) {
    return max - num;
  };

  // uncal age range slider
  var $uncal_range = $(".uncal-range-slider"),
    min = -50000,
    max = 0;

  $uncal_range.ionRangeSlider({
    skin: "flat",
    type: "double",
    min: min,
    max: max,
    from: -gon.uncal_age_start,
    to: -gon.uncal_age_stop,
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
    skin: "flat",
    type: "double",
    min: min,
    max: max,
    from: -gon.cal_age_start,
    to: -gon.cal_age_stop,
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
