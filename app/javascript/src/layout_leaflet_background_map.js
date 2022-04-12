var map

document.addEventListener('DOMContentLoaded',function(){

	var bounds = new L.LatLngBounds(new L.LatLng(-180, -180), new L.LatLng(180, 180));

	// #### map ####

	// Define base layers
	var physical = L.tileLayer.provider('CartoDB.PositronNoLabels');
	var satellite = L.tileLayer.provider('Esri.WorldImagery');
	var baseMaps = {
		"Map": physical,
		"Satellite": satellite
	};
	var defaultBaseMap = physical;

	// Create map
	map = L.map('background_map',{
		zoomControl: false,
		minZoom: 3,
		maxBounds: bounds,
		maxBoundsViscosity: 0.75,
		renderer: L.canvas(),
		layers: [defaultBaseMap]
	});

	//add zoom control with your options
	L.control.zoom({
		position:'topright'
	}).addTo(map);

	// Base map toggle
	L.control.layers(baseMaps, null, { collapsed: false, position: 'bottomright' }).addTo(map);

	// Data filter button
	L.Control.FilterButton = L.Control.extend({
		onAdd: function(map) {
			var button = L.DomUtil.create('button', "btn btn-light mb-3");
			button.setAttribute('data-bs-toggle', 'offcanvas');
			button.setAttribute('data-bs-target', '#filterDataOffcanvas');
			button.setAttribute('aria-controls', 'filterDataOffcanvas');
			button.id='button_filter_data_table';
			button.innerHTML='<i class="fa fa-search"></i> Show data filter';
			
			L.DomEvent.disableClickPropagation(button);
						
			return button;
		},

		onRemove: function(map) {
			// Nothing to do here
		}
	});

	L.control.filter_button = function(opts) {
		return new L.Control.FilterButton(opts);
	}

	L.control.filter_button({ position: 'topleft' }).addTo(map);


	var cluster = L.markerClusterGroup();
	
	// load data and add markers to map
	if (typeof gon === 'undefined') {
		// nothing...
	} else {
		var sites = JSON.parse(gon.selected_sites);

		// console.log(sites);

		// prepare markers
		var markers = new Array(sites.length)
		for (var i = 0; i < markers.length; i++) {
			markers[i] = L.circleMarker(
				[sites[i].lat, sites[i].lng], {
					color: 'black',
					fillColor: '#A44A3F',
					fillOpacity: 0.5,
					weight: 2,
					radius: 4,
					id: sites[i].id
				}
			).bindPopup(
				'<h5>' + sites[i].name + '</h5>' + 
				'<hr/>' + 
				'<button class="btn btn-secondary btn-sm" type="submit" onclick="window.location=\'' + '/sites/' + sites[i].id + '\';">' +
				"<i class=\'fa fa-binoculars\'></i> Site" +
				"</button>" +
				'<button class="btn btn-light btn-sm" type="submit" onclick="window.location=\'' + '/table?utf8=✓&query_site=' + sites[i].name + '\';">' +
				"<i class=\'fa fa-filter\'></i> Measurements" +
				"</button>"
			);
		}

		cluster.addLayers(markers);
			
		const layers = [
			...markers
		];
		

/*		const featureGroup = L.featureGroup(
			layers
		).addTo(map);*/
		
/*		cluster.addLayer(markers);*/
		map.addLayer(cluster);

		
/*		map.fitBounds(featureGroup.getBounds(), {maxZoom: 8});*/
	}

	// Set view to bounds of data
	map.fitBounds(cluster.getBounds())

	// #### lasso ####

	// add lasso functionality
	const lasso = L.lasso(map);

	// indicator div
	//var lai = document.getElementById("lasso_active_indicator");
	//lai.style.display = "none";

	function resetSelectedState() {
		map.eachLayer(layer => {
			if (layer instanceof L.Marker) {
				layer.setIcon(new L.Icon.Default());
			} else if (layer instanceof L.Path) {
				layer.setStyle({ color: 'black' });
			}
		});
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

		const lasso_selected_sites = new Array(layers.length)
		for (var i = 0; i < lasso_selected_sites.length; i++) {
			lasso_selected_sites[i] = layers[i].options.id
		}

		//alert(JSON.stringify(lasso_selected_sites));
		$.ajax({
			type: "post",
			beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
			url: '/data/index',
			dataType: 'json',
			data: { spatial_lasso_selection: JSON.stringify(lasso_selected_sites) },
			success: function(data) {
				window.location.href = '/map'
			},
			error: function(e) {
				alert("Oops! An error occurred, please try again");
				return console.log(e);
			}
		});

		//lai.style.display = "block";

	}

	map.on('mousedown', () => {
		/*resetSelectedState();
		cluster.refreshClusters(markers);*/
	});

	map.on('lasso.finished', event => {
		//cluster.disableClustering()
		setSelectedLayers(event.layers);
	});

	map.on('lasso.enabled', () => {
		cluster.disableClustering()
		resetSelectedState();
	});

	map.on('lasso.disabled', () => {
		//cluster.enableClustering()
	});

	toggleLasso.addEventListener('click', () => {
		if (lasso.enabled()) {
			lasso.disable();
		} else {
			lasso.enable();
		}
	});

	turnoffLasso.addEventListener('click', () => {

		$.ajax({
			type: "get",
			url: '/turn_off_lasso',
			success: function(data) {
				return location.reload();
			},
			error: function(e) {
				alert("Oops! An error occurred, please try again");
				return console.log(e);
			}
		});

		//lai.style.display = "none";

	});
	
});

