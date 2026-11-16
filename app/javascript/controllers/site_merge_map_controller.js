import { Controller } from "@hotwired/stimulus"
import L from "leaflet"
import "leaflet-providers"

export default class extends Controller {
  static targets = ["container", "source", "latitude", "longitude"]
  static values = { sites: Array, cartoApiKey: String }

  connect() {
    const mapTiles = L.tileLayer.provider("CartoDB.Positron", { apikey: this.cartoApiKeyValue })
    const imagery = L.tileLayer.provider("Esri.WorldImagery")
    this.map = L.map(this.containerTarget, { minZoom: 2, maxZoom: 17, layers: [mapTiles] })
    L.control.layers({ Map: mapTiles, Imagery: imagery }).addTo(this.map)
    L.control.scale({ imperial: false }).addTo(this.map)

    this.markers = L.featureGroup().addTo(this.map)
    this.sitesValue.forEach((site, index) => {
      this.addMarker([site.lat, site.lng], site.color, index === 0 ? 12 : 8, site.label)
    })
    this.updateCustomMarker()
    this.fitPoints()
  }

  disconnect() {
    this.map?.remove()
    this.map = null
    this.customMarker = null
  }

  updateCustomMarker() {
    if (!this.map) return

    if (this.customMarker) {
      this.markers.removeLayer(this.customMarker)
      this.customMarker = null
    }

    if (this.sourceTarget.value !== "custom") return

    const latitude = this.coordinate(this.latitudeTarget.value, 90)
    const longitude = this.coordinate(this.longitudeTarget.value, 180)
    if (latitude === null || longitude === null) return

    this.customMarker = this.addMarker([latitude, longitude], "#008450", 4, "Custom coordinates")
  }

  fitPoints() {
    const bounds = this.markers.getBounds()
    if (bounds.isValid()) {
      this.map.fitBounds(bounds, { padding: [28, 28], maxZoom: 16 })
    } else {
      this.map.setView([0, 0], 2)
    }
  }

  addMarker(point, color, radius, label) {
    const text = document.createElement("span")
    text.textContent = label
    return L.circleMarker(point, { color, radius, weight: 3, fill: radius === 4 })
      .bindTooltip(text)
      .addTo(this.markers)
  }

  coordinate(input, limit) {
    const text = input.trim()
    if (!/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:e[+-]?\d+)?$/i.test(text)) return null

    const value = Number(text)
    return Number.isFinite(value) && Math.abs(value) <= limit ? value : null
  }
}
