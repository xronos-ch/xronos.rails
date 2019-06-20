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

  const markers = new Array(sel.length)
	for (var i = 0; i < markers.length; i++) { 
		markers[i] = L.circle(
			[sel[i].site_lat, sel[i].site_lng], {
				color: 'blue',
				fillColor: 'blue',
				fillOpacity: 0.5,
				radius: 1000,
				measurements_id: sel[i].measurements_id
			}
		).bindPopup("I am a circle: " + sel[i].measurements_id);
	}

	const layers = [
      ...markers
  ];

	const featureGroup = L.featureGroup(
		layers
	).addTo(map);

	// add lasso functionality
	const lasso = L.lasso(map);

	function resetSelectedState() {
	  map.eachLayer(layer => {
      if (layer instanceof L.Marker) {
          layer.setIcon(new L.Icon.Default());
      } else if (layer instanceof L.Path) {
          layer.setStyle({ color: 'blue' });
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
        layer.setStyle({ color: 'red' });
      }
    });
    //lassoResult.innerHTML = layers.length ? `First selected ID: ${layers[0].options.measurements_id}` : '';
		const selected_measurements = new Array(layers.length)
		for (var i = 0; i < selected_measurements.length; i++) {
			selected_measurements[i] = layers[i].options.measurements_id
		}
		alert(JSON.stringify(selected_measurements));
		//Rails.ajax({
		//	url: '/welcome/spatial_filter',
		//	data: JSON.stringify(selected_measurements),  // Explicit JSON serialization
		//	contentType: 'application/json',  // Overwrite the default content type: application/x-www-form-urlencoded
		//	success: function(data){
		//	},
		//	dataType : "json"
		//});
  }

  map.on('mousedown', () => {
    resetSelectedState();
  });

  map.on('lasso.finished', event => {
    setSelectedLayers(event.layers);
  });

  map.on('lasso.enabled', () => {
      resetSelectedState();
  });

  map.on('lasso.disabled', () => {
  });

  toggleLasso.addEventListener('click', () => {
    if (lasso.enabled()) {
      lasso.disable();
    } else {
      lasso.enable();
    }
  });

});
