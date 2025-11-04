require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid organizer" do
    user = User.new(
      name: "山田太郎",
      display_name: "Taro",
      email: "taro@example.com",
      password: "Password1",
      password_confirmation: "Password1"
    )

    assert user.valid?
  end

  test "password must be at least eight characters" do
    user = User.new(
      name: "山田太郎",
      display_name: "Taro",
      email: "short@example.com",
      password: "Short1",
      password_confirmation: "Short1"
    )

    assert user.invalid?
    assert_not_empty user.errors[:password]
  end

  test "email must be unique" do
    User.create!(
      name: "山田太郎",
      display_name: "Taro",
      email: "duplicate@example.com",
      password: "Password1",
      password_confirmation: "Password1"
    )

    dup = User.new(
      name: "佐藤花子",
      display_name: "Hanako",
      email: "duplicate@example.com",
      password: "Password1",
      password_confirmation: "Password1"
    )

    assert dup.invalid?
    assert_not_empty dup.errors[:email]
  end
end
