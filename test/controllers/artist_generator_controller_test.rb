require "test_helper"

class ArtistGeneratorControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "should get new" do
    get new_artist_generator_url
    assert_response :success
  end

  test "should create artist" do
    # Stub the ArtistGeneratorService.generate method
    mock_artist = Artist.new(
      user: @user,
      name: "Test Artist",
      genre: "Test Genre",
      energy: 80,
      talent: 70,
      traits: {
        "charisma" => 65,
        "creativity" => 75,
        "resilience" => 60,
        "discipline" => 70
      }
    )
    mock_artist.save

    ArtistGeneratorService.stubs(:generate).returns(mock_artist)

    assert_difference("Artist.count", 0) do # 0 because we're stubbing the service
      post create_artist_generator_url
      assert_redirected_to artist_path(mock_artist)
    end
  end

  test "should generate batch of artists" do
    # Stub the ArtistGeneratorService.generate_batch method
    mock_artists = [
      Artist.new(
        user: @user,
        name: "Test Artist 1",
        genre: "Rock",
        energy: 80,
        talent: 70,
        traits: { "charisma" => 65 }
      ),
      Artist.new(
        user: @user,
        name: "Test Artist 2",
        genre: "Pop",
        energy: 75,
        talent: 65,
        traits: { "creativity" => 70 }
      )
    ]
    mock_artists.each(&:save)

    ArtistGeneratorService.stubs(:generate_batch).returns(mock_artists)

    assert_difference("Artist.count", 0) do # 0 because we're stubbing the service
      post batch_artist_generator_url, params: { count: 2 }
      assert_redirected_to artists_path
    end
  end

  test "should handle generation errors" do
    ArtistGeneratorService.stubs(:generate).raises(ArtistGeneratorService::GenerationError.new("Test error"))

    post create_artist_generator_url
    assert_response :unprocessable_entity
    assert_match "Failed to generate artist", flash[:alert]
  end

  test "should handle invalid artist data errors" do
    ArtistGeneratorService.stubs(:generate).raises(ArtistGeneratorService::InvalidArtistDataError.new("Test error"))

    post create_artist_generator_url
    assert_response :unprocessable_entity
    assert_match "Invalid artist data", flash[:alert]
  end
end
