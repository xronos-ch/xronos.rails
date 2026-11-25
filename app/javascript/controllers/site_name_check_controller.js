import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
	static targets = ["nameField", "message"]

	static values = {
		searchUrl: String,
		siteId: String
	}

	connect() {
		this.queue()
	}

	disconnect() {
		clearTimeout(this.timeout)
		this.request?.abort()
	}

	queue() {
		clearTimeout(this.timeout)
		this.request?.abort()

		const query = this.nameFieldTarget.value.trim()
		this.messageTarget.replaceChildren()
		this.messageTarget.classList.remove("text-muted", "text-warning")
		if (query.length < 3) return

		this.timeout = setTimeout(() => this.fetchSuggestions(query), 450)
	}

	async fetchSuggestions(query) {
		this.messageTarget.textContent = "Checking for existing sites…"
		this.messageTarget.classList.remove("text-warning")
		this.messageTarget.classList.add("text-muted")
		this.request = new AbortController()

		try {
			const url = new URL(this.searchUrlValue, window.location.origin)
			url.searchParams.set("q", query)
			if (this.siteIdValue) url.searchParams.set("exclude_id", this.siteIdValue)

			const response = await fetch(url, {
				headers: { Accept: "application/json" },
				signal: this.request.signal
			})
			if (!response.ok) throw new Error("Site name search failed")

			const sites = await response.json()
			if (!this.queryIsCurrent(query)) return
			this.renderSuggestions(sites)
		} catch (error) {
			if (error.name !== "AbortError" && this.queryIsCurrent(query)) {
				this.messageTarget.classList.remove("text-muted")
				this.messageTarget.classList.add("text-warning")
				this.messageTarget.textContent = "Existing site names could not be checked right now."
			}
		}
	}

	queryIsCurrent(query) {
		return query === this.nameFieldTarget.value.trim()
	}

	renderSuggestions(sites) {
		this.messageTarget.replaceChildren()
		this.messageTarget.classList.remove("text-muted", "text-warning")

		if (sites.length === 0) {
			this.messageTarget.textContent = "No close matches found in the site name search."
			this.messageTarget.classList.add("text-muted", "small", "mt-2")
			return
		}

		const heading = document.createElement("p")
		heading.className = "small text-warning fw-semibold mt-2 mb-1"
		heading.textContent = "Possible existing sites — please check before adding this site:"
		const list = document.createElement("ul")
		list.className = "small mb-2"

		for (const site of sites) {
			const item = document.createElement("li")
			const link = document.createElement("a")
			link.href = `/sites/${encodeURIComponent(site.id)}`
			link.textContent = site.name
			item.append(link)

			const details = []
			if (site.country_code) details.push(site.country_code)
			if (site.lat !== null && site.lng !== null) details.push(`${site.lat}, ${site.lng}`)
			if (details.length > 0) {
				const detail = document.createElement("span")
				detail.className = "text-muted ms-2"
				detail.textContent = details.join(" · ")
				item.append(detail)
			}
			list.append(item)
		}

		this.messageTarget.append(heading, list)
	}
}
