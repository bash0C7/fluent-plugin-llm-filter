# test/plugin/test_filter_llm_generate.rb
require "helper"
require_relative "../../lib/fluent/plugin/filter_llm_generate.rb"
require "json"
require "timeout"

# Mock LLMAlfr::Processor for testing
module LLMAlfr
  class Processor
    attr_reader :model_name, :api_url, :process_calls
    
    def initialize(model_name = nil, api_url = nil)
      @model_name = model_name
      @api_url = api_url
      @process_calls = []
      
      # Simulate initialization failures if specified test model names
      if model_name == "invalid_model"
        raise StandardError, "Invalid model name"
      end
    end
    
    def process(prompt, context, options = {})
      @process_calls << {
        prompt: prompt,
        context: context,
        options: options
      }
      
      # Simulate different behaviors based on context
      if context.include?("timeout")
        sleep 10  # Will trigger timeout in tests
        return "This should never be returned due to timeout"
      elsif context.include?("error")
        raise StandardError, "Processing error"
      else
        return "LLM response: Processed #{context.length} characters"
      end
    end
  end
end

class FilterLlmGenerateTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
    @default_timeout = 1  # Short timeout for testing
  end

  DEFAULT_TAG = "test.message"
  DEFAULT_CONFIG = %[
    prompt Tell me the main topic of this text.
    input_field message
    output_field llm_output
    timeout #{@default_timeout}
  ]
  
  sub_test_case "configuration" do    
    test "custom parameter values" do
      # Arrange
      custom_config = %[
        model_name llama3
        api_url http://localhost:9999/api
        prompt Summarize this text
        input_field content
        output_field summary
        options_json {"temperature": 0.3, "top_p": 0.95}
        timeout 60
      ]
      
      # Act
      d = Fluent::Test::Driver::Filter.new(Fluent::Plugin::LlmGenerateFilter).configure(custom_config)
      
      # Assert
      assert_equal 'llama3', d.instance.model_name
      assert_equal 'http://localhost:9999/api', d.instance.api_url
      assert_equal 'Summarize this text', d.instance.prompt
      assert_equal 'content', d.instance.input_field
      assert_equal 'summary', d.instance.output_field
      assert_equal({"temperature" => 0.3, "top_p" => 0.95}, d.instance.instance_variable_get(:@options))
      assert_equal 60, d.instance.timeout
    end

    # 他のテストケース...
  end
  
  # 他のテストケース...
end
