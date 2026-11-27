import { Controller } from "@hotwired/stimulus"
import L from "leaflet"
import "leaflet/dist/leaflet.css"
import "leaflet-providers"
import Supercluster from "supercluster"

// Connects to data-controller="map"
export default class extends Controller {
  static targets = ["container", "spinner"]
  static values = {
    baseMap: String,
    cartoApiKey: String,
    markersData: Array,
    markersUrl: String,
    style: String
  }

  connect() {
    const bounds = new L.LatLngBounds(
      new L.LatLng(-180, -180),
      new L.LatLng(180, 180)
    )

    // Base maps
    const cartoOptions = { apikey: this.cartoApiKeyValue }
    const physical = L.tileLayer.provider("CartoDB.PositronNoLabels", cartoOptions)
    const labelledPhysical = L.tileLayer.provider("CartoDB.Positron", cartoOptions)
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
      minZoom: this.hasMarkersUrlValue ? 0 : 3,
      maxZoom: 17,
      maxBounds: bounds,
      maxBoundsViscosity: 0.75,
      renderer: L.canvas(),
      preferCanvas: true,
      layers: [baseMap]
    })

    this.map = map

    this.resizeObserver = new ResizeObserver(([entry]) => {
      if (entry.contentRect.width > 0 && entry.contentRect.height > 0) {
        map.invalidateSize({ debounceMoveend: true })
      }
    })
    this.resizeObserver.observe(this.containerTarget)

    // Additional controls
    L.control.layers(baseMaps).addTo(this.map)
    L.control.scale({ imperial: false }).addTo(this.map)

    const index = new Supercluster({
      radius: 60,
      extent: 256,
      maxZoom: 8
    })
    const markersLayer = L.geoJson(null, {
      pointToLayer: this.createClusterIcon
    })
    markersLayer.addTo(map)
    map.fitWorld()

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

    if (this.hasMarkersDataValue) {
      this.loadMarkers()
    }

    if (this.hasMarkersUrlValue) {
      this.loadRemoteMarkers(index, update)
    }
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    this.markersRequest?.abort()
    this.markersRequest = null
    this.hideSpinner()
    this.map?.remove()
    this.map = null
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

  async loadRemoteMarkers(index, update) {
    const request = new AbortController()
    this.markersRequest = request
    this.showSpinner()

    try {
      const response = await fetch(this.markersUrlValue, {
        headers: { Accept: "application/geo+json" },
        signal: request.signal
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const data = await response.json()
      if (!request.signal.aborted && Array.isArray(data) && data.length > 0) {
        index.load(data)
        update()
      }
    } catch (error) {
      if (!request.signal.aborted) {
        console.error("Error loading map data:", error)
      }
    } finally {
      if (!request.signal.aborted) {
        this.markersRequest = null
        this.hideSpinner()
      }
    }
  }

  showSpinner() {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.remove("d-none")
    }
  }

  hideSpinner() {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add("d-none")
    }
  }
}
