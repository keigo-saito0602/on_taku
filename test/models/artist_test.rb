require "test_helper"

class ArtistTest < ActiveSupport::TestCase
  setup do
    @artist = Artist.new(name: "Sample Band", genre: "Rock", kind: :band)
  end

  test "valid default" do
    assert @artist.valid?
  end

  test "rejects duplicated name" do
    @artist.save!

    dupe = Artist.new(name: "Sample Band", genre: "Pop", kind: :dj)
    assert dupe.invalid?
    assert_not_empty dupe.errors[:name]
  end

  test "rejects invalid url" do
    @artist.official_link = "invalid-url"
    assert @artist.invalid?
    assert_not_empty @artist.errors[:official_link]
  end

  test "accepts nested social links" do
    @artist.social_links.build(label: "Twitter", url: "https://twitter.com/sample")
    assert_difference -> { ArtistSocialLink.count }, 1 do
      @artist.save!
    end
    assert_equal [ "Twitter" ], @artist.reload.social_links.pluck(:label)
  end

  test "ignores blank social links" do
    @artist.social_links.build(label: "Instagram", url: "")
    assert_difference -> { ArtistSocialLink.count }, 0 do
      @artist.save!
    end
  end

  test "accepts nested members for band" do
    @artist.members.build(name: "Alice", instrument: "Guitar", role: "Leader")
    assert_difference -> { ArtistMember.count }, 1 do
      @artist.save!
    end
  end

  test "ignores blank members" do
    @artist.members.build(name: "", instrument: "")
    assert_difference -> { ArtistMember.count }, 0 do
      @artist.save!
    end
  end
end
