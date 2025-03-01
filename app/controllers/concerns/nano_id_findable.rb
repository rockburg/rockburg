module NanoIdFindable
  extend ActiveSupport::Concern

  # Override the default find_by_id method to also look for nano_id
  def find_resource(model_class, id_param = :id)
    id = params[id_param]
    model_class.find_by_id_or_nano_id(id)
  end
end
