import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scroll()
  }

  scroll() {
    this.element.classList.toggle("home-nav-at-top", window.scrollY === 0)
  }
}
