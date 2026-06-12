require "test_helper"

class UserProfileTest < ActiveSupport::TestCase
  test "factory is valid" do
    assert build(:user_profile).valid?
  end

  #
  # Association
  #
  test "is invalid without a user" do
    profile = build(:user_profile, user: nil)

    assert_not profile.valid?
    assert_includes profile.errors[:user], "must exist"
  end

  #
  # Affiliation
  #
  test "strips whitespace from affiliation" do
    profile = build(:user_profile, affiliation: "  University of Copenhagen  ")
    profile.valid?

    assert_equal "University of Copenhagen", profile.affiliation
  end

  test "converts blank affiliation to nil" do
    profile = build(:user_profile, affiliation: "   ")
    profile.valid?

    assert_nil profile.affiliation
  end

  test "affiliation is valid when blank" do
    profile = build(:user_profile, affiliation: nil)
    assert profile.valid?
  end

  test "affiliation is invalid if too long" do
    profile = build(:user_profile, affiliation: "a" * 201)

    assert_not profile.valid?
    assert_includes profile.errors[:affiliation], "is too long (maximum is 200 characters)"
  end

  test "affiliation cannot contain line breaks" do
    profile = build(:user_profile, affiliation: "University\nCopenhagen")

    assert_not profile.valid?
  end

  #
  # ORCID
  #
  test "accepts valid orcid (default factory)" do
    profile = build(:user_profile)
    assert profile.valid?
  end

  test "accepts nil orcid" do
    profile = build(:user_profile, :without_orcid)
    assert profile.valid?
  end

  test "rejects invalid orcid format" do
    profile = build(:user_profile, orcid: "invalid")

    assert_not profile.valid?
    assert_includes profile.errors[:orcid], "must be in the format xxxx-xxxx-xxxx-xxxx"
  end

  #
  # Public email
  #
  test "accepts valid public email (default)" do
    profile = build(:user_profile)
    assert profile.valid?
  end

  test "accepts nil public email" do
    profile = build(:user_profile, :no_public_email)
    assert profile.valid?
  end

  test "rejects invalid public email" do
    profile = build(:user_profile, public_email: "invalid_email")

    assert_not profile.valid?
    assert_includes profile.errors[:public_email], "must be a valid email address"
  end

  #
  # URL
  #
  test "accepts valid url (default)" do
    profile = build(:user_profile)
    assert profile.valid?
  end

  test "accepts nil url" do
    profile = build(:user_profile, :no_url)
    assert profile.valid?
  end

  test "rejects invalid url" do
    profile = build(:user_profile, url: "not-a-url")

    assert_not profile.valid?
  end

  #
  # Photo validations
  #
  test "rejects unsupported photo content type" do
    profile = build(:user_profile)

    profile.photo.attach(
      io: StringIO.new("fake"),
      filename: "test.txt",
      content_type: "text/plain"
    )

    profile.valid?

    assert_includes profile.errors[:photo], "must be a supported file type"
    assert_not profile.photo.attached?
  end

  test "rejects photo larger than 5 MB" do
    profile = build(:user_profile)

    profile.photo.attach(
      io: StringIO.new("a" * (5.megabyte + 1)),
      filename: "big.jpg",
      content_type: "image/jpeg"
    )

    profile.valid?

    assert_includes profile.errors[:photo], "must be less than 5 megabytes"
    assert_not profile.photo.attached?
  end

  test "accepts valid photo" do
    profile = build(:user_profile)

    profile.photo.attach(
      io: StringIO.new("a" * 1024),
      filename: "small.jpg",
      content_type: "image/jpeg"
    )

    assert profile.valid?
  end
end
