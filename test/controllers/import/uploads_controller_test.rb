require "test_helper"

class Import::UploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @import = imports(:transaction)
  end

  test "show" do
    get import_upload_url(@import)
    assert_response :success
  end

  test "uploads valid csv by copy and pasting" do
    patch import_upload_url(@import), params: {
      import: {
        raw_file_str: file_fixture("imports/valid.csv").read,
        col_sep: ","
      }
    }

    assert_redirected_to import_configuration_url(@import, template_hint: true)
    assert_equal "Súbor CSV bol nahratý.", flash[:notice]
  end

  test "uploads valid csv by file" do
    patch import_upload_url(@import), params: {
      import: {
        csv_file: file_fixture_upload("imports/valid.csv"),
        col_sep: ","
      }
    }

    assert_redirected_to import_configuration_url(@import, template_hint: true)
    assert_equal "Súbor CSV bol nahratý.", flash[:notice]
  end

  test "invalid csv cannot be uploaded" do
    patch import_upload_url(@import), params: {
      import: {
        csv_file: file_fixture_upload("imports/invalid.csv"),
        col_sep: ","
      }
    }

    assert_response :unprocessable_entity
    assert_equal "Súbor musí byť platné CSV s hlavičkou a aspoň jedným riadkom údajov.", flash[:alert]
  end

  test "official Tatra CSV skips the wizard and imports immediately" do
    assert_difference -> { accounts(:depository).entries.transactions.count }, 10 do
      patch import_upload_url(@import), params: {
        import: {
          csv_file: file_fixture_upload("tatra_export.csv"),
          col_sep: ","
        }
      }
    end

    assert_redirected_to transactions_path
    assert_match(/Naimportovaných/, flash[:notice])
  end
end
