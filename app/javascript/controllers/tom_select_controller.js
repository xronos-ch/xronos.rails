import { Controller } from "@hotwired/stimulus"
import TomSelect      from "tom-select"
import "tom-select/dist/css/tom-select.bootstrap5.min.css"

export default class extends Controller {
	static values = {
		route: String,
		searchMode: Boolean,
		value: String,
		label: String,
		search: String,
		params: String,
		maxItems: Number,
		create: Boolean
	}

	connect() {

		let settings = {
			maxOptions: 255,
			create: this.hasCreateValue ? this.createValue : false,
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

					let url = remoteUrl + '?q=' + encodeURIComponent(query)

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

		new TomSelect(this.element, settings)
	}
}
