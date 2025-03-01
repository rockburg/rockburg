class PagesController < ApplicationController
  # Skip authentication for static pages
  allow_unauthenticated_access

  def home
  end

  def about
  end

  def privacy
  end

  def terms
  end
end
