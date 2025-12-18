import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  
  toggle(event) {
    event.preventDefault()
    
    const button = event.currentTarget
    const originalText = button.textContent
    
    // Provide immediate feedback
    button.textContent = "✓ Taken!"
    button.classList.add("taken")
    button.disabled = true
    
    // Submit the form
    button.form.requestSubmit()
    
    // Reset after a delay if there's an error
    setTimeout(() => {
      if (button.disabled) {
        button.textContent = originalText
        button.classList.remove("taken")
        button.disabled = false
      }
    }, 3000)
  }
}