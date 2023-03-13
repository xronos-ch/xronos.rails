import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="home-hero"
export default class extends Controller {
	static targets = [ "navbar", "search" ]

	connect() {
		this.navbarTarget.classList.remove("sticky-top")
		this.navbarTarget.classList.add("fixed-top")

		if (window.scrollY == 0) {
			this.transparent()
		}
	}

	scroll() {
		if (window.scrollY > 0) {
			this.opaque()
		}
		else {
			this.transparent()
		}
	}

	transparent() {
		this.navbarTarget.classList.add("bg-transparent")
		this.navbarTarget.classList.remove("shadow")

		this.searchTarget.classList.add("visually-hidden")
	}

	opaque() {
		this.navbarTarget.classList.remove("bg-transparent")
		this.navbarTarget.classList.add("shadow")

		this.searchTarget.classList.remove("visually-hidden")
	}

	disconnect() {
		this.opaque()
	}
}
