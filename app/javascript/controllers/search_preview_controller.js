import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
	static targets = ["input", "results"]
	static values = { url: String }

	disconnect() {
		this.clear()
	}

	queue(event) {
		this.clear()
		const query = this.inputTarget.value.trim()
		if (event.isComposing || [...query].length < 3) return

		this.timeout = setTimeout(() => this.fetchResults(query), 300)
	}

	leave(event) {
		if (event.relatedTarget && !this.element.contains(event.relatedTarget)) this.clear()
	}

	dismissOutside(event) {
		if (!this.element.contains(event.target)) this.clear()
	}

	escape(event) {
		if (!this.timeout && !this.request && !this.resultsTarget.hasChildNodes()) return

		event.preventDefault()
		this.inputTarget.focus()
		this.clear()
	}

	clear() {
		clearTimeout(this.timeout)
		this.timeout = null
		this.request?.abort()
		this.request = null
		if (this.hasResultsTarget) this.resultsTarget.replaceChildren()
	}

	async fetchResults(query) {
		this.timeout = null
		const request = new AbortController()
		this.request = request
		const url = new URL(this.urlValue, window.location.origin)
		url.searchParams.set("q", query)

		try {
			const response = await fetch(url, {
				headers: { Accept: "text/html" },
				redirect: "error",
				signal: request.signal
			})
			if (!response.ok) return

			const html = await response.text()
			if (!request.signal.aborted) this.resultsTarget.innerHTML = html
		} catch (error) {
			if (!request.signal.aborted) console.error("Search preview failed", error)
		} finally {
			if (this.request === request) this.request = null
		}
	}
}
