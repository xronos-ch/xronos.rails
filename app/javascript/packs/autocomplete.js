//require("@tarekraafat/autocomplete.js")
import autoComplete from "@tarekraafat/autocomplete.js";

// Configuration for autocomplete fields
// docs: https://tarekraafat.github.io/autoComplete.js/#/usage
$(document).ready(function() {
	const countriesAutocomplete = new autoComplete({ 
		selector: "*[data-autocomplete='countries'",
		wrapper: false,
		data: {
			src: async (query) => {
				try {
					const source = await fetch('/countries.json');
					const data = await source.json();
					return data;
				} catch (error) {
					return error;
				}
			},
			keys: ["name"],
			cache: true
		},
		resultsList: {
			tag: 'div',
			class: 'list-group',
			tabSelect: true,
			noResults: true,
			element: (list, data) => {
				if (!data.results.length) {
					const message = document.createElement("li");
					message.setAttribute("class", "list-group-item list-group-item-danger");
					message.innerHTML = `Unknown country: "${data.query}"</span>`;
					list.appendChild(message);
				}
			},
		},
		resultItem: {
			tag: 'a',
			class: 'list-group-item list-group-item-action text-muted',
			highlight: 'px-0 py-0 bg-transparent text-success fw-bold',
			selected: 'list-group-item-primary'
		}
	});

	countriesAutocomplete.input.addEventListener("selection", function (event) {
		const feedback = event.detail;
		countriesAutocomplete.input.blur();
		// Prepare User's Selected Value
		const selection = feedback.selection.value[feedback.selection.key];
		// Render selected choice to selection div
		//document.querySelector(".selection").innerHTML = selection;
		// Replace Input value with the selected value
		countriesAutocomplete.input.value = selection;
		// Console log autoComplete data feedback
		console.log(feedback);
	});
});
