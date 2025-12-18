import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="wizard"
export default class extends Controller {
  static targets = ["step", "progress", "nextBtn", "prevBtn", "submitBtn"]
  static values = { 
    currentStep: { type: Number, default: 1 },
    totalSteps: { type: Number, default: 4 }
  }

  connect() {
    this.showStep(this.currentStepValue)
    this.updateProgress()
  }

  next(event) {
    event?.preventDefault()
    
    // Validate current step before proceeding
    if (this.validateCurrentStep()) {
      if (this.currentStepValue < this.totalStepsValue) {
        this.currentStepValue++
        this.showStep(this.currentStepValue)
        this.updateProgress()
      }
    }
  }

  previous(event) {
    event?.preventDefault()
    
    if (this.currentStepValue > 1) {
      this.currentStepValue--
      this.showStep(this.currentStepValue)
      this.updateProgress()
    }
  }

  goToStep(event) {
    event?.preventDefault()
    const stepNumber = parseInt(event.currentTarget.dataset.step)
    
    if (stepNumber >= 1 && stepNumber <= this.totalStepsValue) {
      this.currentStepValue = stepNumber
      this.showStep(this.currentStepValue)
      this.updateProgress()
    }
  }

  showStep(stepNumber) {
    // Hide all steps
    this.stepTargets.forEach((step, index) => {
      if (index + 1 === stepNumber) {
        step.classList.remove("hidden")
        step.style.display = "block"
      } else {
        step.classList.add("hidden")
        step.style.display = "none"
      }
    })

    // Update button visibility
    this.updateButtons()

    // Scroll to top of wizard
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  updateProgress() {
    const percentage = (this.currentStepValue / this.totalStepsValue) * 100
    
    if (this.hasProgressTarget) {
      this.progressTarget.style.width = `${percentage}%`
      this.progressTarget.setAttribute('aria-valuenow', percentage)
    }

    // Update step indicators
    const indicators = this.element.querySelectorAll('.step-indicator')
    indicators.forEach((indicator, index) => {
      const stepNum = index + 1
      
      if (stepNum < this.currentStepValue) {
        // Completed step
        indicator.classList.remove('active', 'upcoming')
        indicator.classList.add('completed')
      } else if (stepNum === this.currentStepValue) {
        // Current step
        indicator.classList.remove('completed', 'upcoming')
        indicator.classList.add('active')
      } else {
        // Upcoming step
        indicator.classList.remove('completed', 'active')
        indicator.classList.add('upcoming')
      }
    })
  }

  updateButtons() {
    // Update previous button
    if (this.hasPrevBtnTarget) {
      if (this.currentStepValue === 1) {
        this.prevBtnTarget.style.display = 'none'
      } else {
        this.prevBtnTarget.style.display = 'block'
      }
    }

    // Update next/submit button visibility
    if (this.hasNextBtnTarget && this.hasSubmitBtnTarget) {
      if (this.currentStepValue === this.totalStepsValue) {
        this.nextBtnTarget.style.display = 'none'
        this.submitBtnTarget.style.display = 'block'
      } else {
        this.nextBtnTarget.style.display = 'block'
        this.submitBtnTarget.style.display = 'none'
      }
    }
  }

  validateCurrentStep() {
    const currentStepElement = this.stepTargets[this.currentStepValue - 1]
    
    // Check for required inputs in current step
    const requiredInputs = currentStepElement.querySelectorAll('[required]')
    let isValid = true
    const radioGroups = {}

    requiredInputs.forEach(input => {
      if (input.type === 'radio') {
        // Track radio groups
        if (!radioGroups[input.name]) {
          radioGroups[input.name] = currentStepElement.querySelectorAll(`input[name="${input.name}"]`)
        }
      } else if (!input.value || input.value.trim() === '') {
        isValid = false
        
        // Add visual feedback
        input.style.borderColor = '#ef4444'
        
        // Remove error styling after user interacts
        input.addEventListener('input', () => {
          input.style.borderColor = ''
        }, { once: true })
      }
    })

    // Check radio groups
    Object.values(radioGroups).forEach(group => {
      const hasChecked = Array.from(group).some(radio => radio.checked)
      if (!hasChecked) {
        isValid = false
      }
    })

    if (!isValid) {
      // Show error message
      this.showValidationError('Please fill in all required fields')
    }

    return isValid
  }

  showValidationError(message) {
    // Create or update error message
    let errorEl = this.element.querySelector('.wizard-error')
    
    if (!errorEl) {
      errorEl = document.createElement('div')
      errorEl.className = 'wizard-error bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4'
      this.stepTargets[this.currentStepValue - 1].insertBefore(
        errorEl, 
        this.stepTargets[this.currentStepValue - 1].firstChild
      )
    }

    errorEl.textContent = message

    // Auto-hide after 5 seconds
    setTimeout(() => {
      errorEl.remove()
    }, 5000)
  }

  // Custom event handlers for specific step actions
  selectPillboxType(event) {
    const selectedType = event.currentTarget.value
    
    // Store selected type
    this.element.dataset.selectedType = selectedType
    
    // Highlight selected option
    const radioCards = this.element.querySelectorAll('.pillbox-type-card')
    radioCards.forEach(card => {
      const radio = card.querySelector('input[type="radio"]')
      if (radio && radio.checked) {
        card.classList.add('border-blue-500', 'bg-blue-50')
        card.classList.remove('border-gray-300')
      } else {
        card.classList.remove('border-blue-500', 'bg-blue-50')
        card.classList.add('border-gray-300')
      }
    })
  }

  addCompartment(event) {
    event?.preventDefault()
    
    // This will be implemented in the compartment configuration step
    const compartmentCount = this.element.querySelectorAll('.compartment-item').length
    const maxCompartments = 12
    
    if (compartmentCount >= maxCompartments) {
      this.showValidationError('Maximum 12 compartments allowed')
      return
    }
    
    // Add compartment logic here
  }

  removeCompartment(event) {
    event?.preventDefault()
    const compartmentItem = event.currentTarget.closest('.compartment-item')
    if (compartmentItem) {
      compartmentItem.remove()
    }
  }
}
