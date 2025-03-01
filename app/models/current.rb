class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user

  def user=(user)
    super
    self.session = user.sessions.first if user && session.nil?
  end

  def session=(session)
    super
    self.user = session.user if session && user.nil?
  end
end
