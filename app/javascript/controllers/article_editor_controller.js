import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="article-editor"
export default class extends Controller {
	static targets = [ "title", "slug" ]
	slugHasBeenTouched = false

  connect() {
		if (this.slugTarget.value != '') {
			this.slugHasBeenTouched = true
		}
		this.addSlugifyButton()
  }

	disconnect() {
		this.removeSlugifyButton()
	}

	inputTitle() {
		if (!this.slugHasBeenTouched) {
			this.updateSlug()
		}
	}

	touchSlug() {
		this.slugHasBeenTouched = true
	}

	updateSlug() {
		this.slugTarget.value = this.slugify(this.titleTarget.value)
	}

	// https://www.30secondsofcode.org/js/s/slugify
	slugify(str) {
		return str
			.toLowerCase()
			.trim()
			.replace(/[^\w\s-]/g, '')
			.replace(/[\s_-]+/g, '-')
			.replace(/^-+|-+$/g, '')
	}

	addSlugifyButton() {
		let slugifyBtn = document.createElement("button")
		slugifyBtn.type = "button"
		slugifyBtn.title = "Regenerate slug from title"
		slugifyBtn.classList.add('btn')
		slugifyBtn.classList.add('btn-outline-info')
		slugifyBtn.dataset.action = "article-editor#updateSlug"
		slugifyBtn.innerHTML = '<i class="fa fa-refresh"></i><span class="visually-hidden">Regenerate slug</span>'
		this.slugTarget.parentElement.append(slugifyBtn)
	}

	removeSlugifyButton() {
		// TO DO
	}
}
