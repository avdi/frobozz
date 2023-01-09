require "sequel"
require "roda"
require "rodauth"
require "rodauth/oauth"
require "jwt"

case ENV["ENVIRONMENT"].downcase
when "development"
  DB = Sequel.sqlite
else
  raise "An ENVIRONMENT of #{ENV["ENVIRONMENT"]} is not [yet] supported"
end

DB.create_table :account_statuses do
  Integer :id, primary_key: true
  String :name, null: false, unique: true
end
DB.from(:account_statuses).import([:id, :name], [[1, "Unverified"], [2, "Verified"], [3, "Closed"]])
DB.create_table :accounts do
  primary_key :id, type: :Bignum
  foreign_key :status_id, :account_statuses, null: false, default: 1
  if DB.database_type == :postgresql
    citext :email, null: false
    constraint :valid_email, email: /^[^,;@ \r\n]+@[^,@; \r\n]+\.[^,@; \r\n]+$/
  else
    String :email, null: false
  end
  if DB.supports_partial_indexes?
    index :email, unique: true, where: {status_id: [1, 2]}
  else
    index :email, unique: true
  end

  String :password_hash
end
very_secure_password = BCrypt::Password.create("poop", cost: BCrypt::Engine::MIN_COST).to_s
DB[:accounts].insert email: "avdi@avdi.codes", status_id: 2, password_hash: very_secure_password

module Frobozz
  class App < Roda
    plugin :rodauth, json: true do
      db DB
      account_password_hash_column :password_hash
      enable :login, :logout, :oauth_authorization_code_grant, :jwt
      oauth_application_scopes %w[profile.read profile.write]
    end
    plugin :sessions, secret: "TODO_BETTER_SECRET" * 4
    route do |r|
      r.rodauth
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
