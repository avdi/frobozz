# frozen_string_literal: true

require "rubygems"
require "bundler"

Bundler.require

require_relative "./lib/frobozz/app"

run Frobozz::App.freeze.app
