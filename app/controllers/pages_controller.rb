class PagesController < ApplicationController
  # Skip authentication for static pages
  allow_unauthenticated_access

  before_action :resume_session_if_available

  def home
  end

  def about
  end

  def privacy
  end

  def terms
  end

  private

  def resume_session_if_available
    # Ensures Current.user is set if a valid session exists, even though we don't require authentication
    authenticated?
  end
end
