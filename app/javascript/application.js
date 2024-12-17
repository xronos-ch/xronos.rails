// Entry point for the build script in your package.json
import * as bootstrap from "bootstrap"

import * as ActiveStorage from "@rails/activestorage"
//import "./channels" // https://github.com/xronos-ch/xronos.rails/issues/301

// hotwire (turbo+stimulus)
import "@hotwired/turbo-rails"
import "./controllers"

//fonts
require("@fontsource/inter")
require("@fontsource/raleway")

ActiveStorage.start()
