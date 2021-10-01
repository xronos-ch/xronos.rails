var map

document.addEventListener('DOMContentLoaded',function(){

	var bounds = new L.LatLngBounds(new L.LatLng(-180, -180), new L.LatLng(180, 180));

	// #### map ####

	// define base map
	map = L.map('background_map',{
		zoomControl: false,
		maxBounds: bounds,
		maxBoundsViscosity: 0.75,
		renderer: L.canvas()
	});
	//add zoom control with your options
	L.control.zoom({
		position:'topright'
	}).addTo(map);
	L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
		attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
		maxZoom: 18,
		id: 'mapbox.streets',
		accessToken: 'your.mapbox.access.token'

	}).addTo(map);

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

	if (!map.restoreView()) {
		map.setView([45, 7], 3);
	}

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
	
// https://github.com/makinacorpus/Leaflet.RestoreView
(function() {
	var RestoreViewMixin = {
		restoreView: function () {
			if (!storageAvailable('localStorage')) {
				return false;
			}
			var storage = window.localStorage;
			if (!this.__initRestore) {
				this.on('moveend', function (e) {
					if (!this._loaded)
						return;  // Never access map bounds if view is not set.

					var view = {
						lat: this.getCenter().lat,
						lng: this.getCenter().lng,
						zoom: this.getZoom()
					};
					storage['mapView'] = JSON.stringify(view);
				}, this);
				this.__initRestore = true;
			}

			var view = storage['mapView'];
			try {
				view = JSON.parse(view || '');
				this.setView(L.latLng(view.lat, view.lng), view.zoom, true);
				return true;
			}
			catch (err) {
				return false;
			}
		}
	};

	function storageAvailable(type) {
		try {
			var storage = window[type],
				x = '__storage_test__';
			storage.setItem(x, x);
			storage.removeItem(x);
			return true;
		}
		catch(e) {
			console.warn("Your browser blocks access to " + type);
			return false;
		}
	}

	L.Map.include(RestoreViewMixin);

})();




