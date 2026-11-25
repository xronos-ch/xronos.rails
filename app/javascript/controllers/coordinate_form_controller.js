import { Controller } from "@hotwired/stimulus"
import L from "leaflet"
import "leaflet/dist/leaflet.css"
import { createBaseMaps } from "../map_layers"

export default class extends Controller {
	static targets = [
		"latitudeField", "longitudeField", "decimalInputs", "dmsInputs",
		"latitudeDegrees", "latitudeMinutes", "latitudeSeconds", "latitudeHemisphere",
		"longitudeDegrees", "longitudeMinutes", "longitudeSeconds", "longitudeHemisphere",
		"map", "mapMessage", "country", "countryMessage", "applyCountryButton", "formatField"
	]

	static values = {
		countryUrl: String,
		cartoApiKey: String,
		initialMode: String
	}

	connect() {
		this.mode = this.initialModeValue === "dms" ? "dms" : "decimal"
		this.lastCountryQuery = null
		this.countryTimeout = null
		this.countryRequest = null
		this.handleModalShown = () => this.mapInstance?.invalidateSize()
		this.modalElement = this.element.closest(".modal")
		this.modalElement?.addEventListener("shown.bs.modal", this.handleModalShown)
		this.initializeMap()
		this.updateModeVisibility()
		const coordinatesValid = this.mode !== "dms" || this.updateCoordinatesFromDms()
		this.updatePreview(coordinatesValid)
		this.queueCountrySuggestion(coordinatesValid)
	}

	disconnect() {
		clearTimeout(this.countryTimeout)
		this.countryRequest?.abort()
		this.modalElement?.removeEventListener("shown.bs.modal", this.handleModalShown)
		this.mapInstance?.remove()
	}

	changeFormat(event) {
		const nextMode = event.currentTarget.value
		if (nextMode === this.mode) return

		if (this.mode === "dms" && !this.updateCoordinatesFromDms()) {
			this.element.querySelector(":invalid")?.reportValidity()
			return
		}
		this.mode = nextMode
		this.formatFieldTarget.value = nextMode
		this.updateModeVisibility(event.currentTarget)

		if (this.mode === "dms") {
			this.populateDms("latitude")
			this.populateDms("longitude")
		}
		this.coordinatesChanged()
	}

	updateModeVisibility(selectedButton = null) {
		const showDms = this.mode === "dms"
		this.decimalInputsTargets.forEach(target => target.classList.toggle("d-none", showDms))
		this.dmsInputsTargets.forEach(target => target.classList.toggle("d-none", !showDms))
		this.element.querySelectorAll(".btn-group button[value]").forEach(button => {
			const active = selectedButton ? button === selectedButton : button.value === this.mode
			button.classList.toggle("active", active)
			button.setAttribute("aria-pressed", active)
		})
	}

	coordinatesChanged() {
		const coordinatesValid = this.mode !== "dms" || this.updateCoordinatesFromDms()
		this.updatePreview(coordinatesValid)
		this.queueCountrySuggestion(coordinatesValid)
	}

	countryChanged() {
		if (this.hasCountryTarget && this.countrySuggestion) this.renderCountrySuggestion(this.countrySuggestion)
	}

	applyCountrySuggestion() {
		if (!this.hasCountryTarget) return
		if (!this.countrySuggestion?.country_code) return

		if (this.countryTarget.tomselect) {
			this.countryTarget.tomselect.setValue(this.countrySuggestion.country_code)
		} else {
			this.countryTarget.value = this.countrySuggestion.country_code
			this.countryTarget.dispatchEvent(new Event("change", { bubbles: true }))
		}
		this.renderCountrySuggestion(this.countrySuggestion)
	}

	prepareSubmission(event) {
		if (!this.element.closest("form")?.contains(event.target)) return
		if (this.mode !== "dms") return

		if (!this.updateCoordinatesFromDms()) {
			event.preventDefault()
			this.element.querySelector(":invalid")?.reportValidity()
		}
	}

	initializeMap() {
		if (!this.hasMapTarget) return

		const baseMap = createBaseMaps(this.cartoApiKeyValue).Imagery
		this.mapInstance = L.map(this.mapTarget, {
			zoomControl: true,
			scrollWheelZoom: false,
			layers: [baseMap]
		}).setView([20, 0], 2)
		this.marker = L.circleMarker([0, 0], {
			color: "#212529",
			fillColor: "#a44a3f",
			fillOpacity: 0.9,
			weight: 2,
			radius: 7
		})
	}

	updatePreview(coordinatesValid = true) {
		if (!this.hasMapTarget || !this.hasMapMessageTarget || !this.marker) return

		const coordinates = this.currentCoordinates()
		if (!coordinatesValid || !coordinates || !this.inRange(coordinates.latitude, coordinates.longitude)) {
			this.marker.remove()
			this.mapMessageTarget.textContent = "Enter valid latitude and longitude to preview the location."
			this.mapMessageTarget.classList.remove("d-none")
			return
		}

		this.mapMessageTarget.classList.add("d-none")
		this.marker.setLatLng([coordinates.latitude, coordinates.longitude]).addTo(this.mapInstance)
		if (!this.mapHasLocation) {
			this.mapInstance.setView([coordinates.latitude, coordinates.longitude], 8)
			this.mapHasLocation = true
		} else {
			this.mapInstance.panTo([coordinates.latitude, coordinates.longitude])
		}
		this.mapInstance.invalidateSize()
	}

	currentCoordinates() {
		const latitude = Number(this.latitudeFieldTarget.value)
		const longitude = Number(this.longitudeFieldTarget.value)
		if (this.latitudeFieldTarget.value.trim() === "" || this.longitudeFieldTarget.value.trim() === "") return null
		if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null
		return { latitude, longitude }
	}

	currentCoordinatesKey() {
		if (this.mode === "dms" && !this.updateCoordinatesFromDms()) return null

		const coordinates = this.currentCoordinates()
		return coordinates ? `${coordinates.latitude},${coordinates.longitude}` : null
	}

	queueCountrySuggestion(coordinatesValid = true) {
		if (!this.countryUrlValue || !this.hasCountryTarget || !this.hasCountryMessageTarget || !this.hasApplyCountryButtonTarget) return

		clearTimeout(this.countryTimeout)
		const coordinates = this.currentCoordinates()
		if (!coordinatesValid || !coordinates || !this.inRange(coordinates.latitude, coordinates.longitude)) {
			this.clearCountrySuggestion()
			return
		}

		const key = `${coordinates.latitude},${coordinates.longitude}`
		if (key === this.lastCountryQuery && this.countrySuggestion) {
			this.renderCountrySuggestion(this.countrySuggestion)
			return
		}

		this.clearCountrySuggestion()

		this.countryTimeout = setTimeout(() => this.fetchCountrySuggestion(coordinates, key), 800)
	}

	clearCountrySuggestion() {
		this.countryRequest?.abort()
		this.countrySuggestion = null
		this.countryMessageTarget.textContent = ""
		this.countryMessageTarget.classList.remove("text-muted", "text-success", "text-warning")
		this.countryMessageTarget.classList.add("d-none")
		this.applyCountryButtonTarget.classList.add("d-none")
	}

	async fetchCountrySuggestion(coordinates, key) {
		this.countryRequest = new AbortController()
		this.countryMessageTarget.textContent = "Checking the country…"
		this.countryMessageTarget.classList.add("text-muted")
		this.countryMessageTarget.classList.remove("d-none")

		try {
			const url = new URL(this.countryUrlValue, window.location.origin)
			url.searchParams.set("lat", coordinates.latitude)
			url.searchParams.set("lng", coordinates.longitude)
			const response = await fetch(url, {
				headers: { Accept: "application/json" },
				signal: this.countryRequest.signal
			})
			if (!response.ok) throw new Error("Country lookup failed")
			const suggestion = await response.json()
			if (key !== this.currentCoordinatesKey()) return

			this.countrySuggestion = suggestion
			this.lastCountryQuery = key
			this.renderCountrySuggestion(suggestion)
		} catch (error) {
			if (error.name !== "AbortError" && key === this.currentCoordinatesKey()) {
				this.countryMessageTarget.textContent = "The country could not be checked right now."
				this.countryMessageTarget.classList.add("text-warning")
				this.countryMessageTarget.classList.remove("text-muted")
				this.countryMessageTarget.classList.remove("d-none")
			}
		}
	}

	renderCountrySuggestion(suggestion) {
		this.countryMessageTarget.classList.remove("d-none")
		this.countryMessageTarget.classList.remove("text-muted", "text-success", "text-warning")
		this.applyCountryButtonTarget.classList.add("d-none")

		if (!suggestion?.country_code) {
			this.countryMessageTarget.textContent = "No country could be identified for these coordinates."
			this.countryMessageTarget.classList.add("text-muted")
			return
		}

		const selectedOption = this.countryTarget.selectedOptions[0]
		const selectedCode = this.countryTarget.value
		const countryName = suggestion.country_name || suggestion.country_code

		if (selectedCode === suggestion.country_code) {
			this.countryMessageTarget.textContent = `The coordinates are consistent with ${countryName}.`
			this.countryMessageTarget.classList.add("text-success")
			return
		}

		const selectedCountry = selectedOption?.value ? selectedOption.textContent.trim() : null
		this.countryMessageTarget.textContent = selectedCountry
			? `The coordinates appear to be in ${countryName}, but ${selectedCountry} is selected. Please check both values.`
			: `The coordinates appear to be in ${countryName}. Please check this suggestion.`
		this.countryMessageTarget.classList.add("text-warning")
		this.applyCountryButtonTarget.textContent = `Use ${countryName}`
		this.applyCountryButtonTarget.classList.remove("d-none")
	}

	populateDms(axis) {
		const field = axis === "latitude" ? this.latitudeFieldTarget : this.longitudeFieldTarget
		const value = Number(field.value)
		if (field.value.trim() === "" || !Number.isFinite(value)) {
			this[`${axis}DegreesTarget`].value = ""
			this[`${axis}MinutesTarget`].value = ""
			this[`${axis}SecondsTarget`].value = ""
			this[`${axis}HemisphereTarget`].value = axis === "latitude" ? "N" : "E"
			return
		}

		const absoluteValue = Math.abs(value)
		const degrees = Math.floor(absoluteValue)
		const minuteValue = (absoluteValue - degrees) * 60
		const minutes = Math.floor(minuteValue)
		const seconds = ((minuteValue - minutes) * 60).toFixed(6).replace(/0+$/, "").replace(/\.$/, "")
		this[`${axis}DegreesTarget`].value = degrees
		this[`${axis}MinutesTarget`].value = minutes
		this[`${axis}SecondsTarget`].value = seconds
		this[`${axis}HemisphereTarget`].value = value < 0
			? (axis === "latitude" ? "S" : "W")
			: (axis === "latitude" ? "N" : "E")
	}

	updateCoordinatesFromDms() {
		const latitude = this.dmsCoordinate("latitude", 90)
		const longitude = this.dmsCoordinate("longitude", 180)
		if (latitude === false || longitude === false) return false

		this.latitudeFieldTarget.value = latitude ?? ""
		this.longitudeFieldTarget.value = longitude ?? ""
		return true
	}

	dmsCoordinate(axis, maximumDegrees) {
		const degreesField = this[`${axis}DegreesTarget`]
		const minutesField = this[`${axis}MinutesTarget`]
		const secondsField = this[`${axis}SecondsTarget`]
		const hemisphereField = this[`${axis}HemisphereTarget`]
		const degrees = Number(degreesField.value)
		const minutes = Number(minutesField.value)
		const seconds = Number(secondsField.value)
		const fields = [degreesField, minutesField, secondsField]
		const empty = fields.every(field => field.value.trim() === "")
		if (empty) {
			fields.forEach(field => field.setCustomValidity(""))
			return null
		}
		const invalid = fields.some(field => field.value.trim() === "") ||
			!Number.isInteger(degrees) || degrees < 0 || degrees > maximumDegrees ||
			!Number.isInteger(minutes) || minutes < 0 || minutes >= 60 ||
			!Number.isFinite(seconds) || seconds < 0 || seconds >= 60 ||
			(degrees === maximumDegrees && (minutes !== 0 || seconds !== 0))

		for (const field of [degreesField, minutesField, secondsField]) {
			field.setCustomValidity(invalid ? "Enter valid degrees, minutes, and seconds." : "")
		}
		if (invalid) return false

		const absoluteValue = degrees + minutes / 60 + seconds / 3600
		return ["S", "W"].includes(hemisphereField.value) ? -absoluteValue : absoluteValue
	}

	inRange(latitude, longitude) {
		return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
	}
}
