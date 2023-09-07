import { Controller } from "@hotwired/stimulus"
import noUiSlider from "nouislider";
import "nouislider/dist/nouislider.css";
import wNumb from "wnumb";

// Connects to data-controller="slider"
export default class extends Controller {
	static targets = [ "minInput", "maxInput", "slider" ]
	static values = {
		step: Number,
		direction: String,
		formatter: String,
		range: Object,
		density: Number
	}

  connect() {
		this.element.classList.add("has-slider");

		var minInput = this.minInputTarget;
		var maxInput = this.maxInputTarget;

		// slider parameters
		var step = (this.stepValue != 0 ? this.stepValue : 1);
		var direction = (this.directionValue != '' ? this.directionValue : 'ltr');
		var range = (this.hasRangeValue ? this.rangeValue : this.defaultRange());
		var density = (this.densityValue != 0 ? this.densityValue : 1);

		this.slider = noUiSlider.create(this.sliderTarget, {
			start: [minInput.value, maxInput.value],
			connect: true,
			step: step,
			direction: direction,
			tooltips: this.formatter(),
			range: range,
			pips: {
				mode: 'range',
				density: density,
				format: this.formatter()
			}
		});

		this.slider.on('update', function(values, handle) {
			minInput.value = values[0];
			maxInput.value = values[1];
		})
	}

	disconnect() {

	}

	formatter() {
		var formatters = {
			"integer": wNumb({ decimal: 0 }),
			"uncalBP": wNumb({
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
