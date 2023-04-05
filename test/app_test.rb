require_relative "test_helper"
require "rack/test"
require_relative "../lib/frobozz/app"
require "json"

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

  it "saves and returns new rooms" do
    post "/rooms", {name: "Kitchen"}.to_json, "CONTENT_TYPE" => "application/json"

    get "/rooms"

    room_list = JSON.parse(last_response.body)
    assert_equal [{"name" => "Kitchen"}], room_list

    post "/rooms", {name: "Den"}.to_json, "CONTENT_TYPE" => "application/json"

    get "/rooms"

    room_list = JSON.parse(last_response.body)
    assert_includes(room_list, {"name" => "Den"})
  end
end
