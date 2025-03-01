class Admin::SeasonsController < ApplicationController
  include AdminAuthentication
  before_action :set_season, only: [ :show, :edit, :update, :destroy ]

  def index
    @seasons = Season.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @season = Season.new
  end

  def edit
  end

  def create
    @season = Season.new(season_params)

    if @season.save
      redirect_to admin_season_path(@season), notice: "Season was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @season.update(season_params)
      redirect_to admin_season_path(@season), notice: "Season was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @season.destroy
    redirect_to admin_seasons_path, notice: "Season was successfully destroyed."
  end

  private

  def set_season
    @season = Season.find(params[:id])
  end

  def season_params
    params.require(:season).permit(:name, :description, :active, :started_at, :ended_at, :transition_ends_at, :settings, :genre_trends)
  end
end
