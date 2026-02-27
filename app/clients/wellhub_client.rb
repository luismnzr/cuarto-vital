class WellhubClient
  BASE_URL = ENV.fetch("WELLHUB_API_URL", "https://api.partners.gympass.com")

  class Error < StandardError
    attr_reader :status, :body

    def initialize(message, status: nil, body: nil)
      @status = status
      @body = body
      super(message)
    end
  end

  class << self
    # --- Access Control API ---

    def validate_checkin(gym_id:, gympass_id:)
      post("/access/v1/validate", { gym_id: gym_id, gympass_id: gympass_id })
    end

    # --- Booking API: Classes ---

    def create_class(gym_id:, attributes:)
      post("/booking/v1/gyms/#{gym_id}/classes", attributes)
    end

    def update_class(gym_id:, class_id:, attributes:)
      patch("/booking/v1/gyms/#{gym_id}/classes/#{class_id}", attributes)
    end

    def list_classes(gym_id:)
      get("/booking/v1/gyms/#{gym_id}/classes")
    end

    # --- Booking API: Slots ---

    def create_slot(gym_id:, class_id:, attributes:)
      post("/booking/v1/gyms/#{gym_id}/classes/#{class_id}/slots", attributes)
    end

    def update_slot(gym_id:, class_id:, slot_id:, attributes:)
      patch("/booking/v1/gyms/#{gym_id}/classes/#{class_id}/slots/#{slot_id}", attributes)
    end

    def list_slots(gym_id:, class_id:, from:, to:)
      get("/booking/v1/gyms/#{gym_id}/classes/#{class_id}/slots", from: from, to: to)
    end

    # --- Booking API: Bookings ---

    def update_booking(gym_id:, booking_number:, status:)
      patch("/booking/v2/gyms/#{gym_id}/bookings/#{booking_number}", { status: status })
    end

    # --- Booking API: Categories ---

    def list_categories(gym_id:, locale: "en")
      get("/booking/v1/gyms/#{gym_id}/categories", locale: locale)
    end

    # --- Integration Setup API: Webhooks ---

    def register_webhooks(gym_id:, webhooks:)
      post("/v1/systems/gyms/#{gym_id}/webhooks", { webhooks: webhooks })
    end

    def list_webhooks(gym_id:)
      get("/v1/systems/gyms/#{gym_id}/webhooks")
    end

    private

    def get(path, params = {})
      uri = URI("#{BASE_URL}#{path}")
      uri.query = URI.encode_www_form(params) if params.any?

      request = Net::HTTP::Get.new(uri)
      execute(uri, request)
    end

    def post(path, body)
      uri = URI("#{BASE_URL}#{path}")
      request = Net::HTTP::Post.new(uri)
      request.body = body.to_json
      execute(uri, request)
    end

    def patch(path, body)
      uri = URI("#{BASE_URL}#{path}")
      request = Net::HTTP::Patch.new(uri)
      request.body = body.to_json
      execute(uri, request)
    end

    def execute(uri, request)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 15

      response = http.request(request)

      case response.code.to_i
      when 200..299
        return nil if response.body.blank?
        begin
          JSON.parse(response.body)
        rescue JSON::ParserError
          raise Error.new(
            "Wellhub API returned non-JSON response: #{response.body.truncate(200)}",
            status: response.code.to_i,
            body: response.body
          )
        end
      else
        raise Error.new(
          "Wellhub API error: #{response.code} #{response.message}",
          status: response.code.to_i,
          body: response.body
        )
      end
    end

    def api_key
      ENV.fetch("WELLHUB_API_KEY")
    end
  end
end
