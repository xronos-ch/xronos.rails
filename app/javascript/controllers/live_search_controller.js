import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
	disconnect() {
		this.cancel()
	}

	queue(event) {
		this.cancel()
		const query = event.target.value.trim()
		if (event.isComposing || (query && [...query].length < 3)) return

		this.timeout = setTimeout(() => this.element.requestSubmit(), 450)
	}

	cancel() {
		clearTimeout(this.timeout)
	}
}
