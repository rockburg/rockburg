require "test_helper"

class ArtistSelectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
    # Create an unassigned artist (no manager)
    @unassigned_artist = Artist.create!(
      name: "Unassigned Artist",
      genre: "Alternative",
      energy: 80,
      talent: 70
    )
  end

  test "should get index" do
    # Stub the ArtistPoolService to prevent actual API calls
    ArtistPoolService.stubs(:ensure_minimum_artists_available).returns(nil)

    get artist_selections_url
    assert_response :success
  end

  test "should select an artist" do
    # Verify artist starts with no manager
    assert_nil @unassigned_artist.manager

    post select_artist_url(@unassigned_artist)

    @unassigned_artist.reload
    # Now artist should be associated with the current user's manager
    assert_equal @user.manager, @unassigned_artist.manager
    assert_redirected_to artist_path(@unassigned_artist)
  end

  test "should not select an already assigned artist" do
    # Assign the artist to another user's manager
    other_user = users(:two)
    other_manager = other_user.manager || other_user.create_manager(
      budget: 1000.00,
      level: 1,
      xp: 0,
      skill_points: 0,
      traits: {},
      nano_id: SecureRandom.alphanumeric(10)
    )
    @unassigned_artist.update!(manager: other_manager)

    post select_artist_url(@unassigned_artist)

    @unassigned_artist.reload
    # Artist should still be associated with the other manager
    assert_equal other_manager, @unassigned_artist.manager
    assert_redirected_to artists_path
    assert_match "already been signed", flash[:alert]
  end

  test "should filter artists by affordability" do
    get artist_selections_url, params: { affordable: true }
    assert_response :success
    assert assigns(:artists).all? { |artist| artist.affordable_for?(@user.manager) }
  end

  test "should filter artists by eligibility level" do
    get artist_selections_url, params: { eligible: true }
    assert_response :success
    assert assigns(:artists).all? { |artist| artist.eligible_for?(@user.manager) }
  end

  test "should filter artists by genre" do
    genre = "Rock"
    get artist_selections_url, params: { genre: genre }
    assert_response :success
    assert assigns(:artists).all? { |artist| artist.genre == genre }
  end

  test "should sort artists by cost" do
    get artist_selections_url, params: { sort: "cost" }
    assert_response :success
    sorted_artists = assigns(:artists).sort_by(&:signing_cost)
    assert_equal sorted_artists, assigns(:artists)
  end

  test "should sort artists by level" do
    get artist_selections_url, params: { sort: "level" }
    assert_response :success
    sorted_artists = assigns(:artists).sort_by(&:required_level)
    assert_equal sorted_artists, assigns(:artists)
  end

  test "should sort artists by talent" do
    get artist_selections_url, params: { sort: "talent" }
    assert_response :success
    sorted_artists = assigns(:artists).sort_by(&:talent).reverse
    assert_equal sorted_artists, assigns(:artists)
  end
end
