import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "custom"]

  connect() {
    this.update()
  }

  update() {
    this.customTarget.hidden = this.sourceTarget.value !== "custom"
  }
}
