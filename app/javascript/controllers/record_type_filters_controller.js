import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["type", "section"]

  connect() {
    this.update()
  }

  update() {
    const selected = this.typeTargets.filter(input => input.checked).map(input => input.value)

    for (const section of this.sectionTargets) {
      // Submitting without a type selection uses the server's default of all types.
      const visible = selected.length === 0 || selected.includes(section.dataset.recordType)
      section.hidden = !visible
      section.disabled = !visible
    }
  }
}
