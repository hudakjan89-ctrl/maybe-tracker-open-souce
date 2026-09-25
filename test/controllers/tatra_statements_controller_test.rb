require "test_helper"

class TatraStatementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
  end

  test "new renders import dialog" do
    get new_tatra_statement_path
    assert_response :success
    assert_select "h2", text: /Tatra banky/
  end

  test "new preselects account from query param" do
    get new_tatra_statement_path, params: { account_id: accounts(:savings).id }
    assert_response :success
    assert_select "option[value=?][selected]", accounts(:savings).id
  end

  test "create imports uploaded statement" do
    file = Tempfile.new([ "vypis", ".txt" ])
    file.write("24.07.2026 Kaufland -69,00\n26.07.2026 Spotify -6,00\n")
    file.rewind

    assert_difference -> { accounts(:depository).entries.transactions.count }, 2 do
      post tatra_statement_path, params: {
        account_id: accounts(:depository).id,
        statement: Rack::Test::UploadedFile.new(file.path, "text/plain")
      }
    end

    assert_redirected_to transactions_path
  ensure
    file.close!
    file.unlink
  end

  test "create imports official Tatra CSV statement" do
    csv = file_fixture_upload("tatra_export.csv")

    assert_difference -> { accounts(:depository).entries.transactions.count }, 10 do
      post tatra_statement_path, params: {
        account_id: accounts(:depository).id,
        statement: csv
      }
    end

    assert_redirected_to transactions_path
  end
end
