$(document).ready(function() {
  $(".navbar").addClass("fixed-top");
  $(".navbar").addClass("mb-4");
  $(".navbar").addClass("bg-transparent");

  $(window).scroll(function() {    
    var scroll = $(window).scrollTop();

    //>=, not <=
    if (scroll <= 1) {
      //clearHeader, not clearheader - caps H
      $(".navbar").addClass("bg-transparent");
    } else {
      $(".navbar").removeClass("bg-transparent");
    }
  }); //missing );

  // document ready  
});

