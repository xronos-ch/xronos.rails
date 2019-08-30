document.addEventListener('DOMContentLoaded',function(){

  // #### map ####

  // define base map
  const map = L.map('background_map');
  L.tileLayer('https://maps.heigit.org/openmapsurfer/tiles/roads/webmercator/{z}/{x}/{y}.png', {
    attribution: 'Imagery from <a href="http://giscience.uni-hd.de/">GIScience Research Group @ University of Heidelberg</a> | Map data &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    maxZoom: 18,
    id: 'mapbox.streets',
    accessToken: 'your.mapbox.access.token'
  }).addTo(map);

  if (!map.restoreView()) {
    map.setView([45, 7], 3);
  }

  // load data
  var sites = JSON.parse(gon.selected_sites);

  //console.log(sites);

  // sumcal function
  /*function get_c14_measurement_ids(sel, site_id) {
    var values = '';
    for (i = 0; i < sel.length; i++) {
      if (sel[i].site_id == site_id) {
        values = values + 'ids[]=' + sel[i].c14_measurement_id + '&';
      }
    }
    alert(values);
    window.open('/c14_measurements/1/calibrate_sum?' + values, 'Calibration', 'height=800,width=1000,resizable=yes,scrollbars=yes,status=yes');
  }*/

  // prepare markers
  const markers = new Array(sites.length)
	for (var i = 0; i < markers.length; i++) {
		markers[i] = L.circle(
			[sites[i].lat, sites[i].lng], {
				color: 'black',
				fillColor: "black",
				fillOpacity: 0.5,
				radius: 1000,
				id: sites[i].id
			}
		).bindPopup(
      'Site: ' + sites[i].name +
      "<br>" +
      '<button type="submit" onclick="window.location=\'' + '/sites/' + sites[i].id + '\';">' +
        "<i class=\'fa fa-binoculars\'></i> Show site" +
      "</button>" +
      '<br>' +
      '<button type="submit" onclick="window.location=\'' + '/?utf8=✓&query_site_name=' + sites[i].name + '\';">' +
        "<i class=\'fa fa-filter\'></i> Measurements from this site" +
      "</button>"
    );
	}

  //console.log(markers);

	const layers = [
      ...markers
    ];

	const featureGroup = L.featureGroup(
		layers
	).addTo(map);

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
            url: '/data/index',
            dataType: 'json',
            data: { spatial_lasso_selection: JSON.stringify(lasso_selected_sites) },
            success: function(data) {
              return location.reload();
            },
            error: function(e) {
              alert("Oops! An error occurred, please try again");
              return console.log(e);
            }
        });

        //lai.style.display = "block";

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
