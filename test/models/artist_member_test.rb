require "test_helper"

class ArtistMemberTest < ActiveSupport::TestCase
  setup do
    @artist = Artist.create!(name: "Combo", genre: "Jazz", kind: :band)
  end

  test "valid member" do
    member = @artist.members.build(name: "Bob", instrument: "Piano")
    assert member.valid?
  end

  test "marks blank member for destruction" do
    member = @artist.members.build(name: "", instrument: "")
    member.valid?
    assert member.marked_for_destruction?
  end
end
