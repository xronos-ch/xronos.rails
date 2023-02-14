import { Controller } from "@hotwired/stimulus"
import L from "leaflet"
import "leaflet-providers"
import "leaflet-lasso"
import "leaflet-spin"
import Supercluster from 'supercluster';

// Connects to data-controller="map"
export default class extends Controller {
	static targets = [ "container" ]
	static values = {
		baseMap: String,
		markersData: Array,
		markersUrl: String,
		style: String
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
		var map = L.map(this.containerTarget, {
			minZoom: 3,
			maxZoom: 17,
			maxBounds: bounds,
			maxBoundsViscosity: 0.75,
			renderer: L.canvas(),
			preferCanvas: true,
			layers: [baseMap]
		})

		this.map = map;

		// Additional controls
		L.control.layers(baseMaps, null, 
			{ collapsed: false }
		).addTo(this.map)

		L.control.scale({ imperial: false }).addTo(this.map);

		const index = new Supercluster({
			radius: 60,
			extent: 256,
			maxZoom: 8
		});

		this.index = index;

		var markersLayer = L.geoJson(null, {
			pointToLayer: this.createClusterIcon
		});

		this.markersLayer = markersLayer;

		this.markersLayer.addTo(this.map);

		// Initial view
		this.map.fitWorld();

		this.load()

		function update() {
			const bounds = map.getBounds();
			markersLayer.clearLayers();
			markersLayer.addData(index.getClusters([bounds.getWest(), bounds.getSouth(), bounds.getEast(), bounds.getNorth()], map.getZoom()));
		}

		map.on('moveend', function() {
			if (typeof index.points !== "undefined") {
				update()
			}
		});

		markersLayer.on('click', function (e) {
			var extend = index.getClusterExpansionZoom(e.layer.feature.properties.cluster_id);
			if (!isNaN(extend)) {
				map.flyTo(e.latlng, extend);
			}
		})      
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

		if (this.hasStyleValue) {
			if (this.styleValue == "show_site") {
				markers = this.markersDataValue
					.map(data =>
						L.circle(
							[data.lat, data.lng], {
								color: '#b99555',
								fillColor: '#b99555',
								fillOpacity: 0.5,
								weight: 2,
								radius: 300,
								weight: 10,
								id: data.id
							}
						)
					)
			}
		}

		markers = L.featureGroup(markers)
		markers.addTo(this.map)
		this.map.fitBounds(markers.getBounds())
	}

	createClusterIcon(feature, latlng) {
		if (!feature.properties.cluster) return L.circleMarker(
			latlng, {
				color: 'black',
				fillColor: '#A44A3F',
				fillOpacity: 0.5,
				weight: 2,
				radius: 4,
				id: feature.properties.id
			}).bindPopup(
				'<h5>' + feature.properties.name + '</h5>' + 
				'<a class="btn btn-primary btn-sm" style="color: #fff" href="/sites/' + feature.properties.id + '" target="_blank">' +
				'Site details <i class="fa fa-external-link"></i>' +
				'</a>' +
				//'<button class="btn btn-light btn-sm" type="submit" onclick="window.location=\'' + '/table?utf8=✓&query_site=' + feature.properties.name + '\';">' +
				//"<i class=\'fa fa-filter\'></i> Measurements" +
				//"</button>"
				''
			);

		const count = feature.properties.point_count;
		const size =
			count < 100 ? 'small' :
			count < 1000 ? 'medium' : 'large';
		const icon = L.divIcon({
			html: `<div><span>${  feature.properties.point_count_abbreviated  }</span></div>`,
			className: `marker-cluster marker-cluster-${  size}`,
			iconSize: L.point(40, 40)
		});

		return L.marker(latlng, {icon});
	}

	loadRemoteMarkers() {
		// Construct URL to markers data
		var markers_url = new URL(this.markersUrlValue)
		markers_url.search += "&select[]=sites.id&select[]=sites.name&select[]=sites.lat&select[]=sites.lng"
		console.debug("Fetching map data from " + markers_url.toString())
		this.map.spin(true)

		// Load markers
		var data = fetch(markers_url, { headers: { 'Accept': 'application/json' } })
			.then(response => response.json())
			.then(data => {
				data = data.xrons
				var markers = data.filter(data => data.lat && data.lng)
					.map(data => {
						var obj = L.marker(
							[data.lat, data.lng], {
								id: data.id,
								name: data.name
							}
						).toGeoJSON();
						obj.properties = {name: data.name, id:data.id};
						return obj;
					}
					)

				if (markers.length > 0) {
					this.index.load(markers);
					const bounds = this.map.getBounds();
					this.markersLayer.addData(this.index.getClusters([bounds.getWest(), bounds.getSouth(), bounds.getEast(), bounds.getNorth()], this.map.getZoom()));                        //this.map.addLayer(index);    
				}
				this.map.spin(false)

			})
	}
}
