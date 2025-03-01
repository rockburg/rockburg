class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Add a class method to find a record by its nano_id for all models
  def self.find_by_nano_id(id)
    find_by(nano_id: id)
  end

  # Define a convenience method to find by either id or nano_id
  def self.find_by_id_or_nano_id(id)
    # Try to find by primary key first, then by nano_id
    find_by(id: id) || find_by(nano_id: id)
  end
end
