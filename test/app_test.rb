require "minitest/autorun"
require "rack/test"
require "frobozz/app"

describe Frobozz::App do
  include Rack::Test::Methods

  def app
    Frobozz::App.app
  end

  it "responds to a hello world request" do
    get "/hello"

    assert last_response.ok?
    assert_match(/hello, world/i, last_response.body)
  end
end
