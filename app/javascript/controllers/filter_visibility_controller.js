import { Controller } from "@hotwired/stimulus";

// Stimulus controller to toggle the visibility of accordions based on checkbox selection
// and submit the form automatically when a checkbox is changed.
export default class extends Controller {
  // Define targets for checkboxes and accordions
  static targets = ["checkbox", "accordion"];

  // Called when the controller connects to the DOM
  connect() {
    // Attach event listeners to each checkbox
    this.checkboxTargets.forEach(checkbox => {
      checkbox.addEventListener("change", () => {
        this.toggleAccordions(); // Update the visibility of accordions

        // Submit the closest form when a checkbox is changed
        event.target.closest("form").submit();
      });
    });

    // Initialize the visibility of accordions on page load
    this.toggleAccordions();
  }

  // Function to toggle visibility of accordions based on checkbox states
  toggleAccordions() {
    this.accordionTargets.forEach(accordionWrapper => {
      // Find the checkbox that controls this accordion
      const checkbox = this.checkboxTargets.find(cb => cb.id === accordionWrapper.dataset.filterTarget);

      if (checkbox) {
        // Toggle the "d-none" class based on the checkbox state (hide if unchecked)
        accordionWrapper.classList.toggle("d-none", !checkbox.checked);
      }
    });
  }
}