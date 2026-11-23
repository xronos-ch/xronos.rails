// Entry point for the build script in your package.json
import * as bootstrap from "bootstrap"

import * as ActiveStorage from "@rails/activestorage"
//import "./channels" // https://github.com/xronos-ch/xronos.rails/issues/301

// hotwire (turbo+stimulus)
import "@hotwired/turbo-rails"
import "./controllers"

ActiveStorage.start()

// Fall back to full navigation when Cloudflare challenges a Turbo request.
document.addEventListener("turbo:before-fetch-response", (event) => {
  const response = event.detail.fetchResponse;

  if (response.header("cf-mitigated") !== "challenge") return;

  event.preventDefault();
  window.location.assign(response.location.href);
});
