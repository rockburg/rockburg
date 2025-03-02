import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "venueSelect", "venueCard", "venueDetails", "estimatesPanel",
    "ticketPrice", "dateTime", "duration",
    "venueCapacity", "venueCost", "minTicket", "suggestedTicket",
    "estAttendance", "estRevenue", "estSkillGain", "estPopularityGain",
    "submitButton", "venueContainer", "dateHelp", "priceSlider", "priceValue"
  ]

  connect() {
    // Initialize venue data
    this.venues = JSON.parse(this.element.dataset.venues || '{}')

    // Set up initial state
    this.updateDateHelp()

    // Set up event listeners
    if (this.hasTicketPriceTarget && this.hasPriceSliderTarget) {
      this.priceSliderTarget.addEventListener('input', () => {
        this.ticketPriceTarget.value = this.priceSliderTarget.value
        this.priceValueTarget.textContent = `$${this.priceSliderTarget.value}`
        this.updateEstimates()
      })

      this.ticketPriceTarget.addEventListener('input', () => {
        this.priceSliderTarget.value = this.ticketPriceTarget.value
        this.priceValueTarget.textContent = `$${this.ticketPriceTarget.value}`
        this.updateEstimates()
      })
    }

    if (this.hasDateTimeTarget) {
      this.dateTimeTarget.addEventListener('change', () => this.updateDateHelp())
    }
  }

  selectVenue(event) {
    const venueId = event.currentTarget.dataset.venueId

    // Update the hidden select field
    this.venueSelectTarget.value = venueId

    // Update visual selection
    this.venueCardTargets.forEach(card => {
      if (card.dataset.venueId === venueId) {
        card.classList.add('ring-2', 'ring-blue-500', 'bg-blue-50')
        card.classList.remove('bg-white')
      } else {
        card.classList.remove('ring-2', 'ring-blue-500', 'bg-blue-50')
        card.classList.add('bg-white')
      }
    })

    // Show venue details and update estimates
    this.updateVenueDetails(venueId)
  }

  updateVenueDetails(venueId) {
    if (!venueId || !this.venues[venueId]) {
      this.venueDetailsTarget.classList.add('hidden')
      this.estimatesPanelTarget.classList.add('hidden')
      return
    }

    const venue = this.venues[venueId]

    // Show venue details
    this.venueDetailsTarget.classList.remove('hidden')

    // Update venue details
    this.venueCapacityTarget.textContent = `${venue.capacity} people`
    this.venueCostTarget.textContent = `$${venue.bookingCost}`
    this.minTicketTarget.textContent = `$${venue.minTicketPrice}`
    this.suggestedTicketTarget.textContent = `$${venue.suggestedTicketPrice}`

    // Set ticket price to suggested price
    this.ticketPriceTarget.value = venue.suggestedTicketPrice

    if (this.hasPriceSliderTarget) {
      this.priceSliderTarget.min = venue.minTicketPrice
      this.priceSliderTarget.max = venue.suggestedTicketPrice * 2
      this.priceSliderTarget.value = venue.suggestedTicketPrice
      this.priceValueTarget.textContent = `$${venue.suggestedTicketPrice}`
    }

    // Update estimates
    this.updateEstimates()
  }

  updateEstimates() {
    const venueId = this.venueSelectTarget.value
    if (!venueId || !this.venues[venueId]) return

    const venue = this.venues[venueId]
    const ticketPrice = parseFloat(this.ticketPriceTarget.value) || 0
    const artistPopularity = parseInt(this.element.dataset.artistPopularity) || 1
    const artistSkill = parseInt(this.element.dataset.artistSkill) || 1

    // Simple estimate calculation
    let attendance = Math.floor(venue.capacity * (1 - (ticketPrice / (venue.suggestedTicketPrice * 2))));
    attendance = Math.max(0, Math.min(venue.capacity, attendance));

    // Apply popularity factor
    const popularityFactor = 0.5 + (artistPopularity / 200); // 0.5 to 1.0
    attendance = Math.floor(attendance * popularityFactor);

    // Calculate revenue components
    const grossRevenue = attendance * ticketPrice;
    const venueCut = grossRevenue * 0.2; // Assume 20% venue cut
    const expenses = venue.bookingCost + (attendance * 2); // Booking cost + $2 per attendee
    const merchRevenue = attendance * 5 * (artistPopularity / 100); // $5 per attendee scaled by popularity
    const netRevenue = grossRevenue - venueCut - expenses + merchRevenue;

    // Calculate skill and popularity gains
    const attendanceRatio = attendance / venue.capacity;
    const baseSkillGain = 2 + venue.prestige;
    const skillGain = Math.round(baseSkillGain * (0.5 + (attendanceRatio * 0.5)));

    const basePopularityGain = 3 + (venue.prestige * 2);
    const popularityGain = Math.round(basePopularityGain * (0.5 + (attendanceRatio * 0.5)));

    // Show estimates
    this.estimatesPanelTarget.classList.remove('hidden')

    // Update estimate displays
    this.estAttendanceTarget.textContent = `${attendance} / ${venue.capacity} (${Math.round(attendance / venue.capacity * 100)}%)`;
    this.estRevenueTarget.textContent = `$${netRevenue.toFixed(2)}`;

    if (this.hasEstSkillGainTarget) {
      this.estSkillGainTarget.textContent = `+${skillGain}`;
    }

    if (this.hasEstPopularityGainTarget) {
      this.estPopularityGainTarget.textContent = `+${popularityGain}`;
    }

    // Update submit button state
    if (netRevenue < 0) {
      this.submitButtonTarget.classList.add('bg-red-600', 'hover:bg-red-700');
      this.submitButtonTarget.classList.remove('bg-blue-600', 'hover:bg-blue-700');
    } else {
      this.submitButtonTarget.classList.remove('bg-red-600', 'hover:bg-red-700');
      this.submitButtonTarget.classList.add('bg-blue-600', 'hover:bg-blue-700');
    }
  }

  updateDateHelp() {
    if (!this.hasDateHelpTarget) return;

    const selectedDate = new Date(this.dateTimeTarget.value);
    const now = new Date();
    const daysDiff = Math.floor((selectedDate - now) / (1000 * 60 * 60 * 24));

    if (daysDiff < 1) {
      this.dateHelpTarget.textContent = "Must be at least 24 hours in the future";
      this.dateHelpTarget.classList.add('text-red-500');
      this.dateHelpTarget.classList.remove('text-gray-500');
    } else if (daysDiff < 3) {
      this.dateHelpTarget.textContent = "Short notice! This may affect attendance.";
      this.dateHelpTarget.classList.add('text-yellow-500');
      this.dateHelpTarget.classList.remove('text-gray-500', 'text-red-500');
    } else if (daysDiff > 14) {
      this.dateHelpTarget.textContent = "Great planning! Advance booking gives more time for promotion.";
      this.dateHelpTarget.classList.add('text-green-500');
      this.dateHelpTarget.classList.remove('text-gray-500', 'text-red-500', 'text-yellow-500');
    } else {
      this.dateHelpTarget.textContent = "Good timing! At least a week's notice is recommended.";
      this.dateHelpTarget.classList.add('text-gray-500');
      this.dateHelpTarget.classList.remove('text-red-500', 'text-yellow-500', 'text-green-500');
    }
  }
} 