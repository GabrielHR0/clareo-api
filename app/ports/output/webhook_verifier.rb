# The provider authenticates webhooks with a shared static token header, not
# with a per-request signature. Comparison must be constant time and the
# endpoint must reject before persisting anything.
class WebhookVerifier
  # @param presented_token [String] value of the token header
  # @return [Boolean]
  def valid?(presented_token)
    raise NotImplementedError
  end

  # @param event [String] provider event name
  # @return [Boolean]
  def subscribed_to?(event)
    raise NotImplementedError
  end
end
