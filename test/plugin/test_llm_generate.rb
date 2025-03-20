# test/plugin/test_filter_llm_generate.rb (ファイル名変更)
require "helper"
require_relative "../../lib/fluent/plugin/llm_generate.rb" # パス変更
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

class LlmGenerateFilterTest < Test::Unit::TestCase # クラス名変更
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
      d = Fluent::Test::Driver::Filter.new(Fluent::Plugin::LlmGenerateFilter).configure(custom_config) # クラス名変更
      
      # Assert
      assert_equal 'llama3', d.instance.model_name
      assert_equal 'http://localhost:9999/api', d.instance.api_url
      assert_equal 'Summarize this text', d.instance.prompt
      assert_equal 'content', d.instance.input_field
      assert_equal 'summary', d.instance.output_field
      assert_equal({"temperature" => 0.3, "top_p" => 0.95}, d.instance.instance_variable_get(:@options))
      assert_equal 60, d.instance.timeout
    end

    test "invalid JSON in options" do
      # Arrange
      invalid_config = %[
        prompt Tell me the main topic of this text.
        options_json {invalid-json}
      ]
      
      # Act & Assert
      assert_raise do
        Fluent::Test::Driver::Filter.new(Fluent::Plugin::LlmGenerateFilter).configure(invalid_config) # クラス名変更
      end
    end
    
    test "invalid model name" do
      # Arrange
      invalid_config = %[
        model_name invalid_model
        prompt Tell me the main topic of this text.
      ]
      
      # Act & Assert
      assert_raise do
        Fluent::Test::Driver::Filter.new(Fluent::Plugin::LlmGenerateFilter).configure(invalid_config) # クラス名変更
      end
    end
  end
  
  sub_test_case "filtering operation" do
    test "normal operation" do
      # Arrange
      d = Fluent::Test::Driver::Filter.new(Fluent::Plugin::LlmGenerateFilter).configure(DEFAULT_CONFIG) # クラス名変更
      
      # Act
      d.run(default_tag: DEFAULT_TAG) do
        d.feed({"message" => "AI and machine learning are transforming industries."})
      end
      
      # Assert
      filtered_record = d.filtered_records.first
      assert_equal "LLM response: Processed 52 characters", filtered_record["llm_output"]
      
      # Verify the processor was called with correct parameters
      processor = d.instance.instance_variable_get(:@processor)
      assert_equal 1, processor.process_calls.size
      assert_equal "Tell me the main topic of this text.", processor.process_calls[0][:prompt]
      assert_equal "AI and machine learning are transforming industries.", processor.process_calls[0][:context]
    end
    
    test "missing input field" do
      # Arrange
      d = Fluent::Test::Driver::Filter.new(Fluent::Plugin::LlmGenerateFilter).configure(DEFAULT_CONFIG) # クラス名変更
      
      # Act
      d.run(default_tag: DEFAULT_TAG) do
        d.feed({"other_field" => "Some content"})
      end
      
      # Assert
      filtered_record = d.filtered_records.first
      assert_false filtered_record.key?("llm_output")
    end
    
    test "error handling" do
      # Arrange
      d = Fluent::Test::Driver::Filter.new(Fluent::Plugin::LlmGenerateFilter).configure(DEFAULT_CONFIG) # クラス名変更
      
      # Act
      d.run(default_tag: DEFAULT_TAG) do
        d.feed({"message" => "This will cause an error in processing"})
      end
      
      # Assert
      filtered_record = d.filtered_records.first
      assert_true filtered_record["llm_output"].start_with?("Error:")
    end
    
    test "custom options are passed to processor" do
      # Arrange
      custom_config = %[
        prompt Summarize this text
        options_json {"temperature": 0.3, "top_p": 0.95}
        timeout #{@default_timeout}
      ]
      d = Fluent::Test::Driver::Filter.new(Fluent::Plugin::LlmGenerateFilter).configure(custom_config) # クラス名変更
      
      # Act
      d.run(default_tag: DEFAULT_TAG) do
        d.feed({"message" => "Test message"})
      end
      
      # Assert
      processor = d.instance.instance_variable_get(:@processor)
      assert_equal 1, processor.process_calls.size
      assert_equal({"temperature" => 0.3, "top_p" => 0.95}, processor.process_calls[0][:options])
    end
  end
end
