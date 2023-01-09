require "roda"

module Frobozz
  class App < Roda
    route do |r|
      r.on "hello" do
        "Hello, world. The time is now #{Time.now}"
      end

      r.on "rooms" do
        r.is do
          r.get do
          end

          r.post do
            "GOT IT"
          end
        end
      end
    end
  end
end
