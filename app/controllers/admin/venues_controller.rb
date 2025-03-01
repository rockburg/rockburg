module Admin
  class VenuesController < Admin::ApplicationController
    before_action :set_venue, only: [ :show, :edit, :update, :destroy ]

    def index
      @venues = Venue.all.order(tier: :asc, name: :asc)
    end

    def show
    end

    def new
      @venue = Venue.new
    end

    def create
      @venue = Venue.new(venue_params)

      if @venue.save
        redirect_to admin_venue_path(@venue), notice: "Venue was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @venue.update(venue_params)
        redirect_to admin_venue_path(@venue), notice: "Venue was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @venue.performances.exists?
        redirect_to admin_venues_path, alert: "Cannot delete venue with associated performances."
      else
        @venue.destroy
        redirect_to admin_venues_path, notice: "Venue was successfully destroyed."
      end
    end

    private

    def set_venue
      @venue = Venue.find(params[:id])
    end

    def venue_params
      params.require(:venue).permit(:name, :capacity, :booking_cost, :prestige, :tier, :description, preferences: {})
    end
  end
end
