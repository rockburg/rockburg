class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :manager

  def user=(user)
    super
    self.session = user.sessions.first if user && session.nil?
    # Also set the manager to the user's default manager
    self.manager = user.manager if user && manager.nil? && user.manager.present?
  end

  def session=(session)
    super
    self.user = session.user if session && user.nil?
  end

  def manager=(manager)
    super
    # Ensure the manager belongs to the current user
    if manager && user && manager.user_id != user.id
      raise ArgumentError, "Manager must belong to the current user"
    end
  end

  def self.reset
    self.user = nil
    self.session = nil
    self.manager = nil
  end
end
