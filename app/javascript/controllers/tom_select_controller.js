import { Controller } from "@hotwired/stimulus"
import TomSelect      from "tom-select"

// Named render templates for the dropdown rows and selected items. Opt in
// per-input by setting the corresponding *-template Stimulus value to one
// of these names. All template functions must use the +escape+ argument for
// any user-controlled string to avoid XSS.
const TEMPLATES = {

	// Templates for controlled-vocabulary search responses
	"controlled-vocabulary": {
		option: (data, escape) => {
			const variantHint = data.match === "variant" && data.matched_variant
				? ` <span class="fw-normal text-muted">(${escape(data.matched_variant)})</span>`
				: ""

			const header = `
				<div class="d-flex justify-content-between align-items-baseline gap-2">
					<span><span class="fw-semibold">${escape(data.name)}</span>${variantHint}</span>
					${data.ontology_id && data.url ? `
						<a href="${escape(data.url)}" target="_blank" rel="noopener"
				       title="Ontology identifier for '${escape(data.name)}'"
						   class="badge text-bg-info text-decoration-none"
						   onclick="event.stopPropagation();">${escape(data.ontology_id)}</a>
					` : ""}
				</div>
			`

			const description = data.description
				? `<div class="small text-muted">${escape(data.description)}</div>`
				: ""

			const footerParts = []
			if (typeof data.usage_count === "number" && data.usage_count > 0) {
				const noun = data.usage_count === 1 ? "sample" : "samples"
				footerParts.push(
					`<span class="badge rounded-pill text-bg-primary">Used by ${data.usage_count} ${noun}</span>`
				)
			}
			const footer = footerParts.length > 0
				? `<div class="small text-muted">${footerParts.join(" · ")}</div>`
				: ""

			return `<div>${header}${description}${footer}</div>`
		},

		item: (data, escape) => {
			const badge = data.ontology_id && data.url
				? `<a href="${escape(data.url)}" target="_blank" rel="noopener"
				     title="Ontology identifier for '${escape(data.name)}'"
				     class="badge text-bg-info text-decoration-none ms-2">${escape(data.ontology_id)}</a>`
				: ""
			return `<div class="d-flex align-items-center"><span>${escape(data.name)}</span>${badge}</div>`
		}
	}

}

export default class extends Controller {
	static values = {
		route: String,
		searchMode: Boolean,
		value: String,
		label: String,
		search: String,
		params: String,
		maxItems: Number,
		create: Boolean,
		optionTemplate: String,
		itemTemplate: String
	}

	connect() {

		let settings = {
			maxOptions: 255,
			create: this.hasCreateValue ? this.createValue : false,
			createOnBlur: this.hasCreateValue ? this.createValue : false,
			maxItems: this.hasMaxItemsValue ? this.maxItemsValue : null
		}

		// Clear and remove buttons
		settings.plugins = { clear_button: { title: 'Clear' } }
		if (this.element.multiple) {
			settings.plugins.remove_button = { title: 'Remove' }
		}

		// Remote data
		if (this.hasRouteValue) {
			var remoteUrl = '/' + this.routeValue + '.json'

			settings.valueField = this.valueValue
			settings.labelField = this.labelValue
			settings.searchField = this.searchValue
			settings.preload = true

			// with search
			const isSearch = this.searchModeValue
			if (isSearch) {
				settings.shouldLoad = function(query) {
					return query.length > 2
				}

				const controller = this
				settings.load = function(query, callback) {
					var self = this;
					if(self.loading > 1) {
						callback()
						return
					}

					// For preload (query === ''), use the input's current value
					// so any existing selection is among the first results.
					const effectiveQuery = query || self.input.value

					let url = remoteUrl + '?q=' + encodeURIComponent(effectiveQuery)

					// append extra params if present
					if (controller.hasParamsValue && controller.paramsValue.length > 0) {
						url += '&' + controller.paramsValue
					}

					fetch(url)
						.then(response => response.json())
						.then(json => {
							callback(json)
						}).catch(()=>{
							callback()
						})
				}
			}

			// without search (fetch once)
			else {
				settings.load = function(query, callback) {
					var self = this;
					if(self.loading > 1) {
						callback()
						return
					}

					fetch(remoteUrl)
						.then(response => response.json())
						.then(json => {
							callback(json)
							self.settings.load = null
						}).catch(()=>{
							callback()
						})
				}
			}

		}

		// Render templates (opt-in via *-template Stimulus values)
		if (this.hasOptionTemplateValue || this.hasItemTemplateValue) {
			settings.render = settings.render || {}
			if (this.hasOptionTemplateValue) {
				const tpl = TEMPLATES[this.optionTemplateValue]
				if (tpl?.option) settings.render.option = tpl.option
			}
			if (this.hasItemTemplateValue) {
				const tpl = TEMPLATES[this.itemTemplateValue]
				if (tpl?.item) settings.render.item = tpl.item
			}
		}

		new TomSelect(this.element, settings)
	}
}
