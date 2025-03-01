class Session < ApplicationRecord
  include HasNanoId

  belongs_to :user
end
