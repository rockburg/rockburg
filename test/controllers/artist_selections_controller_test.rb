require "test_helper"

class ArtistSelectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)

    # Ensure the user has a manager
    @user.ensure_manager
    @user.manager.update!(name: "Test Manager")

    # Create an unassigned artist (no manager)
    @unassigned_artist = Artist.create!(
      name: "Unassigned Artist",
      genre: "Alternative",
      energy: 80,
      talent: 70
    )

    # Stub the ArtistPoolService to prevent actual API calls
    ArtistPoolService.stubs(:ensure_minimum_artists_available).returns(nil)
  end

  test "should get index" do
    get artist_selections_url
    assert_response :success
  end

  test "should select an artist" do
    # Verify artist starts with no manager
    assert_nil @unassigned_artist.manager

    post select_artist_url(@unassigned_artist)

    @unassigned_artist.reload
    # Now artist should be associated with the current user's manager
    assert_equal @user.manager.id, @unassigned_artist.manager_id
    assert_redirected_to artist_path(@unassigned_artist)
  end

  test "should deduct manager's budget when signing an artist" do
    # Verify artist starts with no manager
    assert_nil @unassigned_artist.manager

    # Set a specific signing cost for the test
    @unassigned_artist.update!(signing_cost: 3750.0)

    # Record the initial budget
    initial_budget = @user.manager.budget
    signing_cost = @unassigned_artist.signing_cost

    post select_artist_url(@unassigned_artist)

    @user.manager.reload
    @unassigned_artist.reload

    # Verify the budget was deducted correctly
    assert_equal initial_budget - signing_cost, @user.manager.budget

    # Verify a transaction was created
    transaction = @user.manager.transactions.last
    assert_equal -signing_cost, transaction.amount
    assert_equal "expense", transaction.transaction_type
    assert_equal @unassigned_artist, transaction.artist
    assert_match "Signed artist", transaction.description
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

    # Get the artists from the response
    artists = assigns(:artists)

    # Check that they are sorted by talent in descending order
    # Compare talent values directly instead of IDs
    assert artists.each_cons(2).all? { |a, b| a.talent >= b.talent }, "Artists are not sorted by talent in descending order"
  end

  test "select should deduct funds from manager's budget" do
    # Create a user and sign in
    user = users(:one)
    sign_in_as(user)

    # Ensure the user has a manager with a budget
    manager = user.ensure_manager
    manager.update!(budget: 1000.00, name: "Test Manager")

    # Create an unassigned artist with a signing cost
    artist = Artist.create!(
      name: "Test Artist",
      genre: "Rock",
      energy: 100,
      talent: 70,
      signing_cost: 500.00,
      required_level: 1,
      max_energy: 100,
      nano_id: SecureRandom.alphanumeric(10)
    )

    # Record the initial budget
    initial_budget = manager.budget

    # Sign the artist using the select action
    post select_artist_url(artist)

    # Reload the manager to get the updated budget
    manager.reload
    artist.reload

    # Verify the artist is now associated with the manager
    assert_equal manager, artist.manager

    # Verify the budget was deducted
    assert_equal initial_budget - artist.signing_cost, manager.budget

    # Verify a transaction was created
    transaction = manager.transactions.last
    assert_equal -artist.signing_cost, transaction.amount
    assert_equal "expense", transaction.transaction_type
    assert_equal artist, transaction.artist
    assert_match "Signed artist", transaction.description

    # Verify the redirect
    assert_redirected_to artist_path(artist)
    assert_match "successfully signed", flash[:notice]
  end
end
