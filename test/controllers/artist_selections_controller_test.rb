require "test_helper"

class ArtistSelectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
    @unassigned_artist = Artist.create!(
      name: "Unassigned Artist",
      genre: "Alternative",
      energy: 80,
      talent: 70,
      user: nil
    )
  end

  test "should get index" do
    # Stub the ArtistPoolService to prevent actual API calls
    ArtistPoolService.stubs(:ensure_minimum_artists_available).returns(nil)

    get artist_selections_url
    assert_response :success
  end

  test "should select an artist" do
    assert_nil @unassigned_artist.user

    post select_artist_url(@unassigned_artist)

    @unassigned_artist.reload
    assert_equal @user.id, @unassigned_artist.user_id
    assert_redirected_to artist_path(@unassigned_artist)
  end

  test "should not select an already assigned artist" do
    # Assign the artist to another user
    other_user = users(:two)
    @unassigned_artist.update!(user: other_user)

    post select_artist_url(@unassigned_artist)

    @unassigned_artist.reload
    assert_equal other_user.id, @unassigned_artist.user_id
    assert_redirected_to artists_path
    assert_match "already been selected", flash[:alert]
  end
end
