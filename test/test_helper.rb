# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "event_engine/definition"

require "minitest/autorun"
require "minitest/reporters"
require "minitest/focus"

Minitest::Reporters.use!

class DefinitionTestCase < Minitest::Test
  def self.test(name, &block)
    define_method("test_#{name.gsub(/\s+/, "_")}", &block)
  end
end
