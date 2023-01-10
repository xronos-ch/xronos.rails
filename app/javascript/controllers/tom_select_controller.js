import { Controller } from "@hotwired/stimulus"
import TomSelect      from "tom-select"

export default class extends Controller {
	static values = {
		route: String,
		value: String,
		label: String,
		search: String
	}

	connect() {
		let settings = {
			maxOptions: 255,
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
			if (remoteUrl.endsWith('search.json')) {
				settings.shouldLoad = function(query) {
					return query.length > 2
				}

				settings.load = function(query, callback) {
					var self = this;
					if(self.loading > 1) {
						callback()
						return
					}

					fetch(remoteUrl + '?q=' + encodeURIComponent(query))
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
