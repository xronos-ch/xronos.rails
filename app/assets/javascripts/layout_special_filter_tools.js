$(document).ready(function() {
    $(".js-range-slider").ionRangeSlider({
        skin: "flat",
        type: "double",
        min: 0,
        max: 2000,
        from: 200,
        to: 1000,
        step: 10,
        drag_interval: true,
        min_interval: 100//,
        //onFinish: function (data) {
          // Called then action is done and mouse is released
        //  $("#query_uncal_age_start").val(data.from);
        //  $("#query_uncal_age_start").val(data.to);
        //}
    });

    const range = $('.js-range-slider');

    const rangeData = range.data('ionRangeSlider');
    const start = rangeData.result.from;
    const stop = rangeData.result.to;

    $("#query_uncal_age_start").val(start);
    $("#query_uncal_age_stop").val(stop);

});
