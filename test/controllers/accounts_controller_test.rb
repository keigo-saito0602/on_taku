require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "Tester",
      display_name: "Tester",
      email: "tester@example.com",
      password: "Password1",
      password_confirmation: "Password1"
    )
  end

  test "redirects when not logged in" do
    get account_url
    assert_redirected_to new_session_url
  end

  test "shows account details when logged in" do
    post session_url, params: { session: { email: @user.email, password: "Password1" } }
    follow_redirect!
    assert_response :success

    get account_url
    assert_response :success
    assert_select "h1", text: "アカウント設定"
  end
end
