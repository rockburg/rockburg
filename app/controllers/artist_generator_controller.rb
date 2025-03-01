class ArtistGeneratorController < ApplicationController
  # Authentication is already handled by the ApplicationController

  def new
    # This action will display the form for generating artists
  end

  def create
    begin
      @artist = ArtistGeneratorService.generate(Current.user)
      redirect_to artist_path(@artist), notice: "Artist '#{@artist.name}' was successfully generated!"
    rescue ArtistGeneratorService::GenerationError => e
      flash.now[:alert] = "Failed to generate artist: #{e.message}"
      render :new, status: :unprocessable_entity
    rescue ArtistGeneratorService::InvalidArtistDataError => e
      flash.now[:alert] = "Invalid artist data: #{e.message}"
      render :new, status: :unprocessable_entity
    end
  end

  def batch
    begin
      count = params[:count].to_i
      count = 10 if count <= 0 || count > 50 # Limit batch size

      @artists = ArtistGeneratorService.generate_batch(count, Current.user)
      redirect_to artists_path, notice: "Successfully generated #{@artists.count} artists!"
    rescue ArtistGeneratorService::GenerationError => e
      flash.now[:alert] = "Failed to generate artists: #{e.message}"
      render :new, status: :unprocessable_entity
    rescue ArtistGeneratorService::InvalidArtistDataError => e
      flash.now[:alert] = "Invalid artist data: #{e.message}"
      render :new, status: :unprocessable_entity
    end
  end
end
