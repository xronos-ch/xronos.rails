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
			[sel[i].lat, sel[i].lng], {
				color: 'blue',
				fillColor: 'blue',
				fillOpacity: 0.5,
				radius: 1000,
				measurement_id: sel[i].measurement_id
			}
		).bindPopup("I am a circle: " + sel[i].measurement_id);
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
		const lasso_selected_measurements = new Array(layers.length)
		for (var i = 0; i < lasso_selected_measurements.length; i++) {
			lasso_selected_measurements[i] = layers[i].options.measurement_id
		}
		//alert(JSON.stringify(lasso_selected_measurements));
		$.ajax({
			type: "get",
			url: '/welcome/index',
            dataType: 'json',
			data: { spatial_lasso_selection: JSON.stringify(lasso_selected_measurements) },
		  success: function(data) {
		    return location.reload();
		  },
		  error: function(e) {
		    alert("Oops! An error occurred, please try again");
		    return console.log(e);
		  }
		});
  }

	var addUrlParam = function(search, key, val){
		var newParam = key + '=' + val,
		    params = '?' + newParam;

		// If the "search" string exists, then build params from it
		if (search) {
		  // Try to replace an existance instance
		  params = search.replace(new RegExp('([?&])' + key + '[^&]*'), '$1' + newParam);

		  // If nothing was replaced, then add the new param to the end
		  if (params === search) {
		    params += '&' + newParam;
		  }
		}

		return params;
	};

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
