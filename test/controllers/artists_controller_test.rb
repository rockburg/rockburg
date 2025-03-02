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

  test "should redirect from edit" do
    get "/artists/#{@artist.id}/edit"
    assert_response :not_found
  end

  test "should not update artist" do
    patch "/artists/#{@artist.id}", params: { artist: { name: "Updated Artist" } }
    assert_response :not_found
    @artist.reload
    assert_not_equal "Updated Artist", @artist.name
  end

  test "should perform activity" do
    post perform_activity_artist_url(@artist), params: { activity: "practice" }
    assert_redirected_to artist_url(@artist)
  end
end
