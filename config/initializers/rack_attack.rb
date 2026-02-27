# Rate limiting and request throttling
# See: https://github.com/rack/rack-attack

class Rack::Attack
  ### Throttle login attempts ###
  # Limit login attempts to 5 per 20 seconds per IP
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # Limit login attempts to 5 per 20 seconds per email
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email")&.downcase&.strip
    end
  end

  ### Throttle sign-up attempts ###
  throttle("signups/ip", limit: 5, period: 60.seconds) do |req|
    req.ip if req.path == "/users" && req.post?
  end

  ### Throttle password reset attempts ###
  throttle("password_resets/ip", limit: 5, period: 60.seconds) do |req|
    req.ip if req.path == "/users/password" && req.post?
  end

  ### Throttle webhook endpoint ###
  throttle("webhooks/ip", limit: 30, period: 60.seconds) do |req|
    req.ip if req.path.start_with?("/webhooks/")
  end

  ### General API throttle ###
  # Limit all requests to 300 per 5 minutes per IP
  throttle("requests/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  ### Custom response for throttled requests ###
  self.throttled_responder = ->(request) {
    retry_after = (request.env["rack.attack.match_data"] || {})[:period]
    [
      429,
      { "Content-Type" => "text/plain", "Retry-After" => retry_after.to_s },
      ["Rate limit exceeded. Try again in #{retry_after} seconds.\n"]
    ]
  }
end
