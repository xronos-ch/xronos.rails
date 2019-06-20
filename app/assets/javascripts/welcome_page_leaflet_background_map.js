document.addEventListener('DOMContentLoaded',function(){
	
	// define base map
	const map = L.map('background_map').setView([45, 7], 3);
	L.tileLayer('https://maps.heigit.org/openmapsurfer/tiles/roads/webmercator/{z}/{x}/{y}.png', {
		  attribution: 'Imagery from <a href="http://giscience.uni-hd.de/">GIScience Research Group @ University of Heidelberg</a> | Map data &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
		  maxZoom: 18,
		  id: 'mapbox.streets',
		  accessToken: 'your.mapbox.access.token'
	}).addTo(map);

	// load markers
	var sel = JSON.parse(gon.selected_measurements);
  const markers = new Array(sel.length).fill(undefined).map((_, i) => L.marker([sel[i].site_lat, sel[i].site_lng]));
	//for (var i = 0; i < sel.length; i++) {
	//	marker = new L.marker([sel[i].site_lat,sel[i].site_lng])
			//.bindPopup(site_name[i])
	//		.addTo(map);
	//}

	const layers = [
      ...markers
  ];

	const featureGroup = L.featureGroup(layers).addTo(map);

	// add lasso functionality
	const lassoControl = L.control.lasso().addTo(map);

	function resetSelectedState() {
		  map.eachLayer(layer => {
		      if (layer instanceof L.Marker) {
		          layer.setIcon(new L.Icon.Default());
		      } else if (layer instanceof L.Path) {
		          layer.setStyle({ color: '#3388ff' });
		      }
		  });
		  lassoResult.innerHTML = '';
	}

  function setSelectedLayers(layers) {
      resetSelectedState();
      layers.forEach(layer => {
          if (layer instanceof L.Marker) {
              layer.setIcon(new L.Icon.Default({ className: 'selected '}));
          } else if (layer instanceof L.Path) {
              layer.setStyle({ color: '#ff4620' });
          }
      });
      lassoResult.innerHTML = layers.length ? `Selected ${layers.length} layers` : '';
  }

  map.on('mousedown', () => {
      resetSelectedState();
  });

  map.on('lasso.finished', event => {
      setSelectedLayers(event.layers);
  });

  map.on('lasso.enabled', () => {
      lassoEnabled.innerHTML = 'Enabled';
      resetSelectedState();
  });

  map.on('lasso.disabled', () => {
      lassoEnabled.innerHTML = 'Disabled';
  });

});
