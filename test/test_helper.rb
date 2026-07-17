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

  def self.setup_blocks
    @setup_blocks ||= []
  end

  def self.teardown_blocks
    @teardown_blocks ||= []
  end

  def self.setup(&block)
    setup_blocks << block
  end

  def self.teardown(&block)
    teardown_blocks << block
  end

  def setup
    each_callback(:setup_blocks) { |block| instance_exec(&block) }
  end

  def teardown
    each_callback(:teardown_blocks) { |block| instance_exec(&block) }
  end

  def assert_nothing_raised
    yield
    assert(true)
  rescue StandardError => e
    raise Minitest::Assertion, "Expected no exception, got #{e.class}: #{e.message}"
  end

  private

  def each_callback(name)
    self.class.ancestors.reverse_each do |ancestor|
      next unless ancestor.respond_to?(name)

      ancestor.public_send(name).each { |block| yield block }
    end
  end
end
