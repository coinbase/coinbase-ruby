module Coinbase
  class Error < StandardError; end
  class ServerError < Error; end
  class TimeoutError < ServerError; end
  class UnauthorizedError < Error; end
  class NotFoundError < Error; end
end
