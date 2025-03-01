import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filterForm", "artistList", "genreInput"]

  connect() {
    this.filterFormTarget.querySelectorAll("select, input[type='checkbox']").forEach(element => {
      element.addEventListener("change", () => this.updateArtists())
    })
    
    // Add debounce for genre search input
    if (this.hasGenreInputTarget) {
      this.genreInputTarget.addEventListener("input", this.debounce(() => {
        this.updateArtists()
      }, 300))
    }
  }

  updateArtists() {
    const url = new URL(window.location.href)
    const formData = new FormData(this.filterFormTarget)
    
    // Clear existing params
    url.search = ""
    
    // Add form data to URL
    formData.forEach((value, key) => {
      if (value) url.searchParams.set(key, value)
    })

    fetch(url, { 
      headers: { 
        "Accept": "text/vnd.turbo-stream.html",
        "Turbo-Frame": "artist-filter-artistList"
      }
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => console.error("Error fetching artists:", error))
  }
  
  // Utility method to debounce function calls
  debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }
} 