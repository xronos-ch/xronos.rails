import { LngLatBounds, Map, NavigationControl, Popup, ScaleControl, setWorkerUrl } from "maplibre-gl"
import "maplibre-gl/dist/maplibre-gl.css"
import { Controller } from "@hotwired/stimulus"

const overlayId = "xronos-sites"
const clustersId = "xronos-clusters"
const clusterCountId = "xronos-cluster-count"
const siteRadius = 300

const imageryStyle = {
  version: 8,
  sources: {
    imagery: {
      type: "raster",
      tileSize: 256,
      tiles: ["https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"],
      attribution: "Tiles &copy; Esri — Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community"
    }
  },
  layers: [{ id: "imagery", type: "raster", source: "imagery" }]
}

const markerLayers = [
  {
    id: overlayId,
    type: "circle",
    source: overlayId,
    filter: ["!", ["has", "point_count"]],
    paint: {
      "circle-color": "#a44a3f",
      "circle-opacity": 0.5,
      "circle-radius": 4,
      "circle-stroke-color": "#000",
      "circle-stroke-width": 2
    }
  },
  {
    id: clustersId,
    type: "circle",
    source: overlayId,
    filter: ["has", "point_count"],
    paint: {
      "circle-color": "#466476",
      "circle-radius": ["step", ["get", "point_count"], 15, 100, 19, 1000, 23]
    }
  },
  {
    id: clusterCountId,
    type: "symbol",
    source: overlayId,
    filter: ["has", "point_count"],
    layout: {
      "text-field": ["to-string", ["get", "point_count_abbreviated"]],
      "text-font": ["Open Sans Regular"],
      "text-size": 12,
      "text-allow-overlap": true
    },
    paint: { "text-color": "#fff" }
  }
]

const siteLayers = [
  {
    id: "xronos-site-area",
    type: "fill",
    source: overlayId,
    paint: { "fill-color": "#b99555", "fill-opacity": 0.5 }
  },
  {
    id: "xronos-site-outline",
    type: "line",
    source: overlayId,
    paint: { "line-color": "#b99555", "line-width": 5 }
  }
]

export default class extends Controller {
  static targets = ["container", "status", "basemap"]
  static values = { markersUrl: String, siteCoordinates: Array, cartoApiKey: String, workerUrl: String }

  connect() {
    const site = this.hasSiteCoordinatesValue ? siteArea(this.siteCoordinatesValue) : null
    this.overlay = { type: "FeatureCollection", features: site ? [site] : [] }
    this.request = new AbortController()
    this.basemapTarget.disabled = true
    const imagery = this.basemapTarget.value === "imagery"
    setWorkerUrl(this.workerUrlValue)

    try {
      this.map = new Map({
        container: this.containerTarget,
        style: this.withOverlay(imagery ? imageryStyle : { version: 8, sources: {}, layers: [] }),
        center: [0, 0],
        zoom: 2,
        minZoom: 2,
        maxZoom: 16,
        dragRotate: false,
        pitchWithRotate: false
      })
    } catch (error) {
      this.statusTarget.textContent = "The map could not start on this device."
      console.error(error)
      return
    }

    this.map.touchZoomRotate.disableRotation()
    this.map.addControl(new NavigationControl({ showCompass: false }))
    this.map.addControl(new ScaleControl({ unit: "metric" }))
    this.map.once("style.load", () => {
      this.basemapTarget.disabled = false
      if (this.basemapTarget.value !== "imagery") this.changeBasemap()
    })

    if (site) {
      const bounds = site.geometry.coordinates[0].reduce((area, point) => area.extend(point), new LngLatBounds())
      this.map.fitBounds(bounds, { padding: 28, duration: 0 })
    } else {
      const clickableLayers = [overlayId, clustersId, clusterCountId]
      const canvas = this.map.getCanvas()
      this.map.on("click", clickableLayers, (event) => this.openFeature(event))
      this.map.on("mouseenter", clickableLayers, () => { canvas.style.cursor = "pointer" })
      this.map.on("mouseleave", clickableLayers, () => { canvas.style.cursor = "" })
      this.loadSites(this.request.signal)
    }
  }

  disconnect() {
    this.request?.abort()
    this.popup?.remove()
    this.popup = null
    this.map?.remove()
    this.map = null
  }

  changeBasemap() {
    const basemap = this.basemapTarget.value
    const style = basemap === "imagery"
      ? imageryStyle
      : `https://basemaps.cartocdn.com/gl/${basemap}-gl-style/style.json?key=${encodeURIComponent(this.cartoApiKeyValue)}`

    this.map.setStyle(style, { transformStyle: (_previous, next) => this.withOverlay(next) })
  }

  async loadSites(signal) {
    this.statusTarget.textContent = "Loading site markers…"
    try {
      const response = await fetch(this.markersUrlValue, {
        headers: { Accept: "application/geo+json" },
        signal
      })
      if (!response.ok) throw new Error(`Marker request returned HTTP ${response.status}`)

      const features = await response.json()
      if (signal.aborted) return
      if (!Array.isArray(features)) throw new Error("Expected an array of site features")

      const map = this.map
      if (!map.getSource(overlayId)) await map.once("style.load")
      if (signal.aborted) return

      this.overlay = { type: "FeatureCollection", features }
      await map.getSource(overlayId).setData(this.overlay)
      if (signal.aborted) return

      this.statusTarget.textContent = features.length ? "" : "No mapped sites match these filters."
    } catch (error) {
      if (signal.aborted) return

      this.statusTarget.textContent = "Site markers could not be loaded."
      console.error(error)
    }
  }

  withOverlay(style) {
    const source = { type: "geojson", data: this.overlay }
    const siteMap = this.hasSiteCoordinatesValue
    if (!siteMap) Object.assign(source, { cluster: true, clusterRadius: 60, clusterMaxZoom: 7 })

    return {
      ...style,
      sources: { ...style.sources, [overlayId]: source },
      layers: [...style.layers, ...(siteMap ? siteLayers : markerLayers)]
    }
  }

  async openFeature(event) {
    const [feature] = event.features ?? []
    if (!feature) return

    const { properties, geometry } = feature
    const map = this.map
    const coordinates = [...geometry.coordinates]
    coordinates[0] += 360 * Math.round((event.lngLat.lng - coordinates[0]) / 360)
    if (properties.cluster) {
      try {
        const zoom = await map.getSource(overlayId).getClusterExpansionZoom(properties.cluster_id)
        if (this.map === map) map.easeTo({ center: coordinates, zoom })
      } catch (error) {
        if (this.map === map) console.error(error)
      }
      return
    }

    const content = document.createElement("div")
    const name = document.createElement("h5")
    name.textContent = properties.name
    const link = document.createElement("a")
    link.className = "btn btn-primary btn-sm"
    link.href = `/sites/${encodeURIComponent(properties.id)}`
    link.target = "_blank"
    link.rel = "noopener"
    link.textContent = "Site details"
    content.append(name, link)

    this.popup?.remove()
    this.popup = new Popup().setLngLat(coordinates).setDOMContent(content).addTo(map)
  }
}

function siteArea([longitude, latitude]) {
  const radians = Math.PI / 180
  const centerLatitude = latitude * radians
  const angularDistance = siteRadius / 6371000
  const sinLatitude = Math.sin(centerLatitude)
  const cosLatitude = Math.cos(centerLatitude)
  const sinDistance = Math.sin(angularDistance)
  const cosDistance = Math.cos(angularDistance)
  // Trace the radius on the globe so the area remains 300 m at every zoom.
  const ring = Array.from({ length: 64 }, (_, step) => {
    const bearing = -step * Math.PI / 32
    const pointLatitude = Math.asin(sinLatitude * cosDistance + cosLatitude * sinDistance * Math.cos(bearing))
    const offsetLongitude = Math.atan2(
      Math.sin(bearing) * sinDistance * cosLatitude,
      cosDistance - sinLatitude * Math.sin(pointLatitude)
    )
    return [longitude + offsetLongitude / radians, pointLatitude / radians]
  })
  ring.push(ring[0])

  return { type: "Feature", properties: {}, geometry: { type: "Polygon", coordinates: [ring] } }
}
