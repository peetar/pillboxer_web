import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { time: String }
  
  connect() {
    this.checkTime()
  }
  
  checkTime() {
    const now = new Date()
    const currentHour = now.getHours()
    
    // Highlight current time period
    const timeRanges = {
      morning: [6, 12],
      afternoon: [12, 17],
      evening: [17, 21],
      bedtime: [21, 24]
    }
    
    const currentRange = timeRanges[this.timeValue]
    if (currentRange && currentHour >= currentRange[0] && currentHour < currentRange[1]) {
      this.element.classList.add("current-time")
    }
  }
}