module HasNanoId
  extend ActiveSupport::Concern

  included do
    before_create :set_nano_id

    validates :nano_id, presence: true, uniqueness: true, allow_nil: true

    # Class method to find a record by its nano_id
    def self.find_by_nano_id(id)
      find_by(nano_id: id)
    end

    # Class method to find by either id or nano_id
    def self.find_by_id_or_nano_id(id)
      find_by(id: id) || find_by(nano_id: id)
    end

    # Override to_param to use nano_id in URLs
    def to_param
      nano_id
    end
  end

  private

  def set_nano_id
    return if nano_id.present?

    # Generate a nanoid
    loop do
      self.nano_id = Nanoid.generate(size: 16, alphabet: "0123456789abcdefghijklmnopqrstuvwxyz")
      break unless self.class.exists?(nano_id: nano_id)
    end
  end
end
