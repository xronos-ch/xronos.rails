document.addEventListener('DOMContentLoaded',function(){
	var mymap = L.map('background_map').setView([45, 7], 3);

	L.tileLayer('https://maps.heigit.org/openmapsurfer/tiles/roads/webmercator/{z}/{x}/{y}.png', {
		  attribution: 'Imagery from <a href="http://giscience.uni-hd.de/">GIScience Research Group @ University of Heidelberg</a> | Map data &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
		  maxZoom: 18,
		  id: 'mapbox.streets',
		  accessToken: 'your.mapbox.access.token'
	}).addTo(mymap);
});