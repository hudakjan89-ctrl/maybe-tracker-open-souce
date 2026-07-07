module ApplicationCable
  class Connection < ActionCable::Connection::Base
    rescue_from StandardError, with: :report_error

    private
      def report_error(error)
        Rails.logger.error("ActionCable error: #{error.message}")
      end
  end
end
