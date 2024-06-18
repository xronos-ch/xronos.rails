import { Controller } from "@hotwired/stimulus"
import vegaEmbed from "vega-embed"

export default class extends Controller {
  static targets = ["selectAll", "checkbox"]

  connect() {
    console.log("TableController connected");

    this.allPagesSelected = false;

    this.selectAllTarget.addEventListener('change', this.toggleSelectAll.bind(this));
  }

  selectAllPage(event) {
    event.preventDefault();
    this.allPagesSelected = false;
    this.toggleCheckboxes(true);
  }

  changeSelectMode(event) {
    event.preventDefault();
    const value = event.target.getAttribute("data-value");
    if (value === "page") {
      this.allPagesSelected = false;
      this.toggleCheckboxes(true);
    } else if (value === "all") {
      this.allPagesSelected = true;
      this.toggleSelectAllAcrossPages();
    }
    console.log(`Select mode changed to: ${value}`);	
  }

  toggleSelectAll(event) {
    const isChecked = event.target.checked;
    this.allPagesSelected = false;
    this.toggleCheckboxes(isChecked);
    console.log(`Toggling checkboxes across all pages: ${this.allPagesSelected}`);
	
  }

  toggleSelectAllAcrossPages() {
    const isChecked = true;
    this.toggleCheckboxes(isChecked);
    console.log(`Toggling checkboxes across all pages: ${this.allPagesSelected}`);
    // Implement the logic to check/uncheck all checkboxes across all pages if needed.
    // This may involve an AJAX call to get all items and update their status accordingly.
    // For now, we'll just log the state change.
  }

  toggleCheckbox(event) {
    this.updateSelectAllState();
  }

  toggleCheckboxes(isChecked) {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = isChecked;
    });
    this.updateSelectAllState();
  }

  updateSelectAllState() {
    const allChecked = this.checkboxTargets.every(checkbox => checkbox.checked);
    const someChecked = this.checkboxTargets.some(checkbox => checkbox.checked);

    this.selectAllTarget.checked = allChecked;
    this.selectAllTarget.indeterminate = !allChecked && someChecked;

    if (this.allPagesSelected && allChecked) {
      this.selectAllTarget.checked = true;
      this.selectAllTarget.indeterminate = false;
    }
  }
    showCalibrationPlot(event) {
        console.log("Showing the calibration plot")

        const calibrationId = this.calibrationIdValue
        const modalElement = document.querySelector('#remote_modal')
        console.log(modalElement ? "#remote_modal found" : "#remote_modal not found")

        if (modalElement) {
          modalElement.addEventListener('shown.bs.modal', () => {
            const plotDataElement = document.querySelector(`#calibration-plot-data`)
            console.log(plotDataElement ? "Calibration plot data found" : "Calibration plot data not found")

            if (plotDataElement) {
              const spec = JSON.parse(plotDataElement.textContent)
              console.log("Vega spec:", spec)

              const chartContainer = document.querySelector('#vega-chart')
              console.log(chartContainer ? "#vega-chart found" : "#vega-chart not found")

              if (chartContainer) {
                vegaEmbed('#vega-chart', spec).then(function(result) {
                  console.log("Vega chart rendered!")
                }).catch(error => {
                  console.error("Error rendering Vega chart:", error)
                })
              } else {
                console.error("#vega-chart does not exist")
              }
            } else {
              console.error("Calibration plot data not found")
            }
          }, { once: true }) // Ensure the event listener is only called once
        }
      }
    
}
