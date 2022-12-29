require "roda"

module Frobozz
  class App < Roda
    route do |r|
      r.on "hello" do
        "Hello, world. The time is now #{Time.now}"
      end
    end
  end
end
