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
          let gbif_id = tom.options[value]?.gbif_id || ""
          this.gbifIdFieldTarget.value = gbif_id
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
