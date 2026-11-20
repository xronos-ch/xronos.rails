import { Controller } from "@hotwired/stimulus"
import noUiSlider from "nouislider";
import wNumb from "wnumb";

// Connects to data-controller="slider"
export default class extends Controller {
	static targets = [ "minInput", "maxInput", "slider", "noscript" ]
	static values = {
		step: Number,
		direction: String,
		formatter: String,
		range: Object,
		density: Number,
		optional: Boolean
	}

  connect() {
	  
        if (this.hasNoscriptTarget) this.noscriptTarget.remove();
	  
		this.element.classList.add("has-slider");

		var minInput = this.minInputTarget;
		var maxInput = this.maxInputTarget;

		// slider parameters
		var step = (this.stepValue != 0 ? this.stepValue : 1);
		var direction = (this.directionValue != '' ? this.directionValue : 'ltr');
		var range = (this.hasRangeValue ? this.rangeValue : this.defaultRange());
		var density = (this.densityValue != 0 ? this.densityValue : 1);

		this.slider = noUiSlider.create(this.sliderTarget, {
			start: [minInput.value || minInput.min, maxInput.value || maxInput.max],
			connect: true,
			step: step,
			direction: direction,
			tooltips: this.formatter(),
			ariaFormat: this.formatter(),
			range: range,
			pips: {
				mode: 'range',
				density: density,
				format: this.formatter()
			}
		});

		const optional = this.optionalValue;
		this.slider.on(optional ? 'change' : 'update', function(values) {
			const minimum = Math.round(Number(values[0]));
			const maximum = Math.round(Number(values[1]));
			minInput.value = optional && minimum === Number(minInput.min) ? "" : String(minimum);
			maxInput.value = optional && maximum === Number(maxInput.max) ? "" : String(maximum);
		})
	}
	

	disconnect() {
		this.slider?.destroy();
	}

	formatter() {
		var formatters = {
			"calendar": {
				to: value => {
					const year = Math.round(value);
					return year > 0 ? `${year} CE` : `${1 - year} BCE`;
				},
				from: value => {
					const year = parseInt(value, 10);
					return String(value).includes("BCE") ? 1 - year : year;
				}
			},
			"integer": wNumb({ decimal: 0 }),
			"uncalBP": wNumb({
				decimal: 0,
				thousand: "&thinsp;"
			}),
			"calBP": wNumb({
				decimal: 0,
				thousand: "&thinsp;"
			})
		}
		return formatters[this.formatterValue];
	}

	defaultRange() {
		return { 
			'min': Number(this.minInputTarget.min), 
			'max': Number(this.minInputTarget.max) 
		};
	}
}
