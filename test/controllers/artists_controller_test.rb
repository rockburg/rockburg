require "test_helper"

class ArtistsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
    @artist = artists(:one)
  end

  test "should get index" do
    get artists_url
    assert_response :success
  end

  test "should get show" do
    get artist_url(@artist)
    assert_response :success
  end

  test "should get new" do
    get new_artist_url
    assert_response :success
  end

  test "should create artist" do
    assert_difference("Artist.count") do
      post artists_url, params: { artist: { name: "New Artist", genre: "Rock", talent: 50, energy: 100 } }
    end

    assert_redirected_to artist_url(Artist.last)
  end

  test "should redirect from edit" do
    get edit_artist_url(@artist)
    assert_redirected_to artist_url(@artist)
    assert_equal "Editing artists is not permitted.", flash[:alert]
  end

  test "should not update artist" do
    patch artist_url(@artist), params: { artist: { name: "Updated Artist" } }
    assert_redirected_to artist_url(@artist)
    assert_equal "Editing artists is not permitted.", flash[:alert]
    @artist.reload
    assert_not_equal "Updated Artist", @artist.name
  end

  test "should perform activity" do
    post perform_activity_artist_url(@artist), params: { activity: "practice" }
    assert_redirected_to artist_url(@artist)
  end
end
