require 'fluent/plugin/filter'
require 'fluent/config/error'
require 'llmalfr'
require 'json'
require 'timeout'

module Fluent
  module Plugin
    class LlmFilter < Filter
      Fluent::Plugin.register_filter('llm_filter', self)

      # Configuration parameters
      desc 'Ollama model name to use'
      config_param :model_name, :string, default: 'hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest'
      
      desc 'Ollama API URL'
      config_param :api_url, :string, default: 'http://localhost:11434/api'
      
      desc 'Prompt for the LLM'
      config_param :prompt, :string
      
      desc 'Input field to extract context from'
      config_param :input_field, :string, default: 'message'
      
      desc 'Output field to store LLM results'
      config_param :output_field, :string, default: 'llm_output'
      
      desc 'JSON string with custom LLM options'
      config_param :options_json, :string, default: '{}'
      
      desc 'Timeout in seconds for LLM processing'
      config_param :timeout, :integer, default: 30

      def configure(conf)
        super
        
        # Parse options JSON
        begin
          @options = JSON.parse(@options_json)
        rescue JSON::ParserError
          raise Fluent::ConfigError, "Invalid JSON in options_json: #{@options_json}"
        end
        
        # Initialize LLM processor
        begin
          @processor = LLMAlfr::Processor.new(@model_name, @api_url)
        rescue => e
          raise Fluent::ConfigError, "Failed to initialize LLM processor: #{e.message}"
        end
      end

      def filter(tag, time, record)
        # Skip processing if input field is missing
        return record unless record.key?(@input_field)
        
        # Get context from input field
        context = record[@input_field].to_s
        
        # Process text with LLM
        begin
          Timeout.timeout(@timeout) do
            record[@output_field] = @processor.process(@prompt, context, @options)
          end
        rescue Timeout::Error
          record[@output_field] = "Error: LLM processing timed out"
        rescue => e
          record[@output_field] = "Error: #{e.message}"
        end
        
        record
      end
    end
  end
end
