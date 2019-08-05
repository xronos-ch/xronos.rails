document.addEventListener('DOMContentLoaded',function(){
  $('#calibrate_link').click(function(event){
    alert('Hooray!');
    event.preventDefault(); // Prevent link from following its href
  });
});
