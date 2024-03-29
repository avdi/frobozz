require "sequel"
require "roda"
require "rodauth"
require "rodauth/oauth"
require "jwt"
require "bcrypt"
require "json"

case ENV["ENVIRONMENT"].to_s.downcase
when "development"
  DB = Sequel.sqlite
  DB_DROP_OPTS = {}
when "production"
  DB = Sequel.connect(ENV.fetch("DATABASE_URL"))
  DB_DROP_OPTS = {cascade: true}
else
  raise "An ENVIRONMENT of #{ENV["ENVIRONMENT"]} is not [yet] supported"
end

DB.drop_table? :account_statuses, **DB_DROP_OPTS
DB.create_table! :account_statuses do
  Integer :id, primary_key: true
  String :name, null: false, unique: true
end
DB.from(:account_statuses).import([:id, :name], [[1, "Unverified"], [2, "Verified"], [3, "Closed"]])
DB.drop_table? :accounts, **DB_DROP_OPTS
DB.create_table! :accounts do
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
DB.drop_table? :oauth_applications, **DB_DROP_OPTS
DB.create_table!(:oauth_applications) do
  primary_key :id, type: Integer
  foreign_key :account_id, :accounts, null: true
  String :name, null: false
  String :description, null: true
  String :homepage_url, null: true
  String :redirect_uri, null: false
  String :client_id, null: false, unique: true
  String :client_secret, null: false, unique: true
  String :scopes, null: false

  String :token_endpoint_auth_method, null: true
  String :grant_types, null: true
  String :response_types, null: true
  String :client_uri, null: true
  String :logo_uri, null: true
  String :tos_uri, null: true
  String :policy_uri, null: true
  String :jwks_uri, null: true
  String :jwks, null: true, type: :text
  String :contacts, null: true
  String :software_id, null: true
  String :software_version, null: true
end
DB.drop_table? :oauth_grants, **DB_DROP_OPTS
DB.create_table! :oauth_grants do |_t|
  primary_key :id, type: Integer
  foreign_key :account_id, :accounts, null: false
  foreign_key :oauth_application_id, :oauth_applications, null: false
  String :type, null: false
  String :code, null: true
  String :token, token: true, unique: true
  String :refresh_token, token: true, unique: true
  DateTime :expires_in, null: false
  String :redirect_uri
  DateTime :revoked_at
  String :scopes, null: false
  index %i[oauth_application_id code], unique: true
  String :access_type, null: false, default: "offline"
  # if using PKCE flow
  String :code_challenge
  String :code_challenge_method
end

very_secure_password =
  BCrypt::Password.create("poop", cost: BCrypt::Engine::MIN_COST).to_s
DB[:accounts].insert email: "avdi@avdi.codes",
  password_hash: very_secure_password,
  status_id: 2

app_secret = BCrypt::Password.create("frobozz-client", cost: BCrypt::Engine::MIN_COST).to_s

DB[:oauth_applications].insert name: "frobozz-client",
  description: "The official client, such as it is",
  homepage_url: "https://frobozz.social",
  redirect_uri: "http://127.0.0.1",
  client_id: "frobozz-client",
  client_secret: app_secret,
  scopes: "profile.read profile.write realm.read realm.write"

$temporary_global_room_list = []
module Frobozz
  class App < Roda
    plugin :rodauth, json: true do
      db DB
      account_password_hash_column :password_hash
      enable :login, :logout, :oauth_base, :oauth_authorization_code_grant, :oauth_pkce, :jwt
      oauth_application_scopes %w[profile.read profile.write]
      authorize_route "oauth/authorize"
      token_route "oauth/token"
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
            JSON.generate($temporary_global_room_list)
          end

          r.post do
            new_room = JSON.parse(request.body.read)
            $temporary_global_room_list << new_room
          end
        end
      end
    end
  end
end
