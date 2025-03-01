require "test_helper"

class HasGeneratedNameTest < ActiveSupport::TestCase
  # We need to modify our approach since we're using before_create
  # which requires ActiveRecord

  test "generates a name when name is blank" do
    # Use the Manager model which includes HasGeneratedName
    user = users(:one)
    manager = user.build_manager(
      budget: 1000.00,
      level: 1,
      xp: 0,
      skill_points: 0,
      traits: {},
      nano_id: SecureRandom.alphanumeric(10)
    )

    # Save to trigger before_create callback
    manager.save!

    assert_not_nil manager.name
    assert_match(/\A[\w']+ [\w']+\z/, manager.name)
  end

  test "combines an adjective and a noun" do
    # Use the Manager model which includes HasGeneratedName
    user = users(:one)
    manager = user.build_manager(
      budget: 1000.00,
      level: 1,
      xp: 0,
      skill_points: 0,
      traits: {},
      nano_id: SecureRandom.alphanumeric(10)
    )

    # Save to trigger before_create callback
    manager.save!

    name_parts = manager.name.split
    assert_equal 2, name_parts.length

    adjective, noun = name_parts
    assert HasGeneratedName::ADJECTIVES.include?(adjective)
    assert HasGeneratedName::NOUNS.include?(noun)
  end
end
