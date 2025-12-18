import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import { registerControllers } from "stimulus-vite-helpers"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Import all controllers
import AutoDismissController from "./controllers/auto_dismiss_controller"
import MedicationToggleController from "./controllers/medication_toggle_controller"
import MedicationTimeController from "./controllers/medication_time_controller"
import WizardController from "./controllers/wizard_controller"

application.register("auto-dismiss", AutoDismissController)
application.register("medication-toggle", MedicationToggleController)  
application.register("medication-time", MedicationTimeController)
application.register("wizard", WizardController)

export { application }