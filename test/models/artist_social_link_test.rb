require "test_helper"

class ArtistSocialLinkTest < ActiveSupport::TestCase
  setup do
    @artist = Artist.create!(name: "Tester", genre: "Pop", kind: :solo)
  end

  test "valid link" do
    link = @artist.social_links.build(label: "YouTube", url: "https://youtube.com/example")
    assert link.valid?
  end

  test "marks blank url for destruction" do
    link = @artist.social_links.build(label: "TikTok", url: "")
    link.valid?
    assert link.marked_for_destruction?
  end
end
