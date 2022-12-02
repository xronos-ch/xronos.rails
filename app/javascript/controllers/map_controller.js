import { Controller } from "@hotwired/stimulus"
import L from "leaflet"
import "leaflet-providers"
import { MarkerClusterGroup } from "leaflet.markercluster"
import "leaflet-lasso"

// Connects to data-controller="map"
export default class extends Controller {
	static targets = [ "container" ]
	static values = {
		baseMap: String,
		markersData: Array,
		markersUrl: String
	}

	connect() {
		var bounds = new L.LatLngBounds(
			new L.LatLng(-180, -180), 
			new L.LatLng(180, 180)
		)

		// Base maps
		var physical = L.tileLayer.provider('CartoDB.PositronNoLabels')
		var labelledPhysical = L.tileLayer.provider('CartoDB.Positron')
		var imagery = L.tileLayer.provider('Esri.WorldImagery')
		var baseMaps = {
			"Map": physical,
			"Map with labels": labelledPhysical,
			"Imagery": imagery
		};

		var baseMap = physical
		if (this.hasBaseMapValue) {
			baseMap = baseMaps[this.baseMapValue]
		}

		// Create map
		this.map = L.map(this.containerTarget, {
			minZoom: 3,
			maxZoom: 17,
			maxBounds: bounds,
			maxBoundsViscosity: 0.75,
			renderer: L.canvas(),
			preferCanvas: true,
			layers: [baseMap]
		})

		// Additional controls
		L.control.layers(baseMaps, null, 
			{ collapsed: false }
		).addTo(this.map)

		L.control.scale({ imperial: false }).addTo(this.map);


		// Initial view
		this.map.fitWorld()

		this.load()
	}

	load() {
		if (this.hasMarkersDataValue) {
			this.loadMarkers()
		}

		if (this.hasMarkersUrlValue) {
			this.loadRemoteMarkers()
		}
	}

	disconnect() {
		this.map.remove()
	}

	loadMarkers() {
		var markers = this.markersDataValue
			.map(data =>
				L.circleMarker(
					[data.lat, data.lng], {
						color: 'black',
						fillColor: '#A44A3F',
						fillOpacity: 0.5,
						weight: 2,
						radius: 4,
						id: data.id
					}
				)
			)
		markers = L.featureGroup(markers)
		markers.addTo(this.map)
		this.map.fitBounds(markers.getBounds())
	}

	loadRemoteMarkers() {
		// Construct URL to markers data
		var markers_url = new URL(this.markersUrlValue)
		markers_url.search += "&select[]=sites.id&select[]=sites.name&select[]=sites.lat&select[]=sites.lng"
		console.debug("Fetching map data from " + markers_url.toString())

		// Load markers
		var data = fetch(markers_url, { headers: { 'Accept': 'application/json' } })
			.then(response => response.json())
			.then(data => {
				data = data.xrons
				var markers = data.filter(data => data.lat && data.lng)
					.map(data => 
						L.circleMarker(
							[data.lat, data.lng], {
								color: 'black',
								fillColor: '#A44A3F',
								fillOpacity: 0.5,
								weight: 2,
								radius: 4,
								id: data.id
							}
						).bindPopup(
							'<h5>' + data.name + '</h5>' + 
							'<a class="btn btn-primary btn-sm" style="color: #fff" href="/sites/' + data.id + '" target="_blank">' +
							'Site details <i class="fa fa-external-link"></i>' +
							'</a>' +
							'<button class="btn btn-light btn-sm" type="submit" onclick="window.location=\'' + '/table?utf8=✓&query_site=' + data.name + '\';">' +
							"<i class=\'fa fa-filter\'></i> Measurements" +
							"</button>"
						)
					)

				if (markers.length > 0) {
					var cluster = L.markerClusterGroup()
					cluster.addLayers(markers, {
						chunkedLoading: true
					})
					const layers = [
						...markers
					];

					this.map.addLayer(cluster);
					this.map.fitBounds(cluster.getBounds())
				}
			})
	}
}
