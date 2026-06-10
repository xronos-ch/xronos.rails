import { Controller } from "@hotwired/stimulus"
import L from "leaflet"
import "leaflet/dist/leaflet.css"
import "leaflet-providers"
import "leaflet-lasso"
import Supercluster from "supercluster"

// Connects to data-controller="map"
export default class extends Controller {
  static targets = ["container", "spinner"]
  static values = {
    baseMap: String,
    markersData: Array,
    markersUrl: String,
    style: String
  }

  connect() {
    // Avoid double-initialisation (e.g. Turbo / Stimulus reconnects)
    if (this._initialized) return
    this._initialized = true

    const bounds = new L.LatLngBounds(
      new L.LatLng(-180, -180),
      new L.LatLng(180, 180)
    )

    // Base maps
    const physical = L.tileLayer.provider("CartoDB.PositronNoLabels")
    const labelledPhysical = L.tileLayer.provider("CartoDB.Positron")
    const imagery = L.tileLayer.provider("Esri.WorldImagery")

    const baseMaps = {
      "Map": physical,
      "Map with labels": labelledPhysical,
      "Imagery": imagery
    }

    let baseMap = physical
    if (this.hasBaseMapValue && baseMaps[this.baseMapValue]) {
      baseMap = baseMaps[this.baseMapValue]
    }

    // Create map
    const map = L.map(this.containerTarget, {
      minZoom: 3,
      maxZoom: 17,
      maxBounds: bounds,
      maxBoundsViscosity: 0.75,
      renderer: L.canvas(),
      preferCanvas: true,
      layers: [baseMap]
    })

    this.map = map

    // Additional controls
    L.control.layers(baseMaps, null, { collapsed: false }).addTo(this.map)
    L.control.scale({ imperial: false }).addTo(this.map)

    const index = new Supercluster({
      radius: 60,
      extent: 256,
      maxZoom: 8
    })
    this.index = index

    const markersLayer = L.geoJson(null, {
      pointToLayer: this.createClusterIcon
    })
    this.markersLayer = markersLayer
    this.markersLayer.addTo(this.map)

    // Initial view
    this.map.fitWorld()

    // Load initial markers (local or remote)
    this.load()

    const update = () => {
      const bounds = map.getBounds()
      markersLayer.clearLayers()
      markersLayer.addData(
        index.getClusters(
          [bounds.getWest(), bounds.getSouth(), bounds.getEast(), bounds.getNorth()],
          map.getZoom()
        )
      )
    }

    map.on("moveend", () => {
      if (typeof index.points !== "undefined") {
        update()
      }
    })

    markersLayer.on("click", e => {
      const extend = index.getClusterExpansionZoom(
        e.layer.feature.properties.cluster_id
      )
      if (!isNaN(extend)) {
        map.flyTo(e.latlng, extend)
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
    if (this.map) {
      this.map.remove()
      this.map = null
    }
    this.index = null
    this.markersLayer = null
    this._initialized = false
    this._markersLoaded = false
    this._markersLoading = false
  }

  loadMarkers() {
    let markers = this.markersDataValue.map(data =>
      L.circleMarker([data.lat, data.lng], {
        color: "black",
        fillColor: "#A44A3F",
        fillOpacity: 0.5,
        weight: 2,
        radius: 4,
        id: data.id
      })
    )

    if (this.hasStyleValue && this.styleValue === "show_site") {
      markers = this.markersDataValue.map(data =>
        L.circle([data.lat, data.lng], {
          color: "#b99555",
          fillColor: "#b99555",
          fillOpacity: 0.5,
          weight: 10,
          radius: 300,
          id: data.id
        })
      )
    }

    const group = L.featureGroup(markers)
    group.addTo(this.map)
    this.map.fitBounds(group.getBounds())
  }

  createClusterIcon(feature, latlng) {
    if (!feature.properties.cluster) {
      return L.circleMarker(latlng, {
        color: "black",
        fillColor: "#A44A3F",
        fillOpacity: 0.5,
        weight: 2,
        radius: 4,
        id: feature.properties.id
      }).bindPopup(
        "<h5>" + feature.properties.name + "</h5>" +
        '<a class="btn btn-primary btn-sm" style="color: #fff" href="/sites/' +
        feature.properties.id +
        '" target="_blank">' +
        'Site details <i class="fa fa-external-link"></i>' +
        "</a>"
      )
    }

    const count = feature.properties.point_count
    const size =
      count < 100 ? "small" :
      count < 1000 ? "medium" : "large"

    const icon = L.divIcon({
      html: `<div><span>${feature.properties.point_count_abbreviated}</span></div>`,
      className: `marker-cluster marker-cluster-${size}`,
      iconSize: L.point(40, 40)
    })

    return L.marker(latlng, { icon })
  }

  loadRemoteMarkers() {
    // Avoid double-fetching (e.g. reconnects or multiple loads)
    if (this._markersLoaded || this._markersLoading) return

    this._markersLoading = true

    const markersUrl = new URL(this.markersUrlValue)
    console.debug("Fetching map data from " + markersUrl.toString())
    this.showSpinner()

    fetch(markersUrl, { headers: { Accept: "application/geo+json" } })
      .then(response => response.json())
      .then(data => {
        // build_geojson_from_sql returns an array of features
        if (Array.isArray(data) && data.length > 0) {
          this.index.load(data)
          const bounds = this.map.getBounds()
          this.markersLayer.addData(
            this.index.getClusters(
              [bounds.getWest(), bounds.getSouth(), bounds.getEast(), bounds.getNorth()],
              this.map.getZoom()
            )
          )
          this._markersLoaded = true
        }
      })
      .catch(error => {
        console.error("Error loading map data:", error)
      })
      .finally(() => {
        this._markersLoading = false
        this.hideSpinner()
      })
  }

  showSpinner() {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.remove("visually-hidden")
    }
  }

  hideSpinner() {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add("visually-hidden")
    }
  }
}
