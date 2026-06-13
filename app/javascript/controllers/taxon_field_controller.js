import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nameField", "gbifIdField"]

  connect() {
    const nameField = this.nameFieldTarget

    const attach = () => {
      const tom = nameField.tomselect
      if (!tom) return

      tom.on("change", (value) => {
        if (this.hasGbifIdFieldTarget) {
          this.gbifIdFieldTarget.value = value || ""
        }
      })

    }

    // TomSelect may initialise after connect
    if (nameField.tomselect) {
      attach()
    } else {
      // fallback: wait until TomSelect is initialised
      requestAnimationFrame(() => attach())
    }
  }
}
