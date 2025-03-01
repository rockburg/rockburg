require "test_helper"

class ArtistPoolServiceTest < ActiveSupport::TestCase
  setup do
    # Delete all unassigned artists to start with a clean slate
    Artist.where(manager_id: nil).delete_all
  end

  test "generates artists when below minimum threshold" do
    # Ensure we have fewer than MIN_AVAILABLE_ARTISTS unassigned artists
    current_count = Artist.where(manager_id: nil).count
    assert current_count < ArtistPoolService::MIN_AVAILABLE_ARTISTS

    # Mock the ArtistGeneratorService to avoid actual API calls
    expected_count = ArtistPoolService::MIN_AVAILABLE_ARTISTS - current_count
    mock_artists = []
    expected_count.times do |i|
      mock_artists << Artist.new(
        name: "Pool Artist #{i}",
        genre: "Test Genre",
        energy: 70,
        talent: 60,
        manager: nil
      )
    end

    ArtistGeneratorService.expects(:generate_batch).with(expected_count).returns(mock_artists)

    # Run the service
    ArtistPoolService.ensure_minimum_artists_available
  end

  test "does not generate artists when above minimum threshold" do
    # Create enough unassigned artists to be above the threshold
    (ArtistPoolService::MIN_AVAILABLE_ARTISTS + 1).times do |i|
      Artist.create!(
        name: "Pool Artist #{i}",
        genre: "Test Genre",
        energy: 70,
        talent: 60,
        manager: nil
      )
    end

    # Mock should not be called
    ArtistGeneratorService.expects(:generate_batch).never

    # Run the service
    ArtistPoolService.ensure_minimum_artists_available
  end

  test "handles errors gracefully" do
    # Ensure we have fewer than MIN_AVAILABLE_ARTISTS unassigned artists
    Artist.where(manager_id: nil).delete_all

    # Mock an error in the generator service
    ArtistGeneratorService.expects(:generate_batch).raises(StandardError.new("Test error"))

    # This should not raise an error
    assert_nothing_raised do
      ArtistPoolService.ensure_minimum_artists_available
    end
  end
end
