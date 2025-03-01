class RegistrationsController < ApplicationController
  skip_before_action :require_authentication, only: [ :new, :create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      # Create a manager for the user
      @user.ensure_manager

      start_new_session_for @user
      redirect_to after_authentication_url, notice: "Welcome to Rockburg! Your account has been created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
end
