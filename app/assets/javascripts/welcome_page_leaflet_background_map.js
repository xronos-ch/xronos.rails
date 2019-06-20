document.addEventListener('DOMContentLoaded',function(){
	var mymap = L.map('background_map').setView([45, 7], 3);

	L.tileLayer('https://maps.heigit.org/openmapsurfer/tiles/roads/webmercator/{z}/{x}/{y}.png', {
		  attribution: 'Imagery from <a href="http://giscience.uni-hd.de/">GIScience Research Group @ University of Heidelberg</a> | Map data &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
		  maxZoom: 18,
		  id: 'mapbox.streets',
		  accessToken: 'your.mapbox.access.token'
	}).addTo(mymap);

	var sel = JSON.parse(gon.selected_measurements);

	for (var i = 0; i < sel.length; i++) {
		marker = new L.marker([sel[i].site_lat,sel[i].site_lng])
			//.bindPopup(site_name[i])
			.addTo(mymap);
	}
});
