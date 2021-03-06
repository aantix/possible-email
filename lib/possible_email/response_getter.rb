STATUS_URL = 'https://rapportive.com/login_status?user_email='
PROFILE_URL = 'https://profiles.rapportive.com/contacts/email/'

module PossibleEmail
  class ResponseGetter
    PROXYS = File.readlines(ENV['PROXYS_FILE']) rescue []
    class << self
      def create_session_token(email)
        status_url = STATUS_URL + email
        response = request_url status_url

        valid_response?(response) ? response['session_token'] : nil
      end

      def retrieve_email_profile_using_session_token(email, session_token)
        profile_url = PROFILE_URL + email
        header = { 'X-Session-Token' => session_token }
        response = request_url profile_url, header

        response.nil? ? nil : response
      end

      private

      def request_url(url, header = {})
        request = HTTPI::Request.new
        request.url     = url
        request.headers = header

        5.times do
          request.proxy = "http://#{ENV['PROXY_USERNAME']}:#{ENV['PROXY_PASSWORD']}@#{PROXYS[rand(PROXYS.size)]}"

          begin
            response = JSON.parse(HTTPI.get(request).body)
            return response
          rescue => e
            # Probably a Net::HTTPFatalError: 503 "Service Unavailable" from the proxy
            sleep 1
          end
        end



      end

      def valid_response?(response)
        response['error'].nil? && response['status'] == 200
      end
    end
  end
end
