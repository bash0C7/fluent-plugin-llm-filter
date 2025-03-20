require 'fluent/plugin/filter'
require 'json'
require 'timeout'
require 'llmalfr'

module Fluent
  module Plugin
    class LlmFilter < Filter
      Fluent::Plugin.register_filter('llm_filter', self)

      desc 'Ollama model name to use'
      config_param :model_name, :string, default: 'hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest'
      
      desc 'Ollama API URL'
      config_param :api_url, :string, default: 'http://localhost:11434/api'
      
      desc 'Prompt to send to the LLM'
      config_param :prompt, :string
      
      desc 'Input field name to extract content from'
      config_param :input_field, :string, default: 'message'
      
      desc 'Output field name to store the LLM result'
      config_param :output_field, :string, default: 'llm_output'
      
      desc 'Custom LLM options in JSON format'
      config_param :options_json, :string, default: '{}'
      
      desc 'Timeout in seconds for LLM processing'
      config_param :timeout, :integer, default: 1
      
      def configure(conf)
        super
        
        # Parse options JSON
        @options = JSON.parse(@options_json)
        
        # Initialize LLM processor
        @processor = LLMAlfr::Processor.new(@model_name, @api_url)
      end
      
      def filter(tag, time, record)
        # Check if input field exists in the record
        unless record.key?(@input_field)
          log.debug("Input field '#{@input_field}' not found in record")
          return record
        end
        
        # Get the content to process
        content = record[@input_field].to_s
        
        # Process with LLM within timeout
        begin
          result = Timeout.timeout(@timeout) do
            @processor.process(@prompt, content, @options)
          end
          record[@output_field] = result
        rescue Timeout::Error
          log.warn("LLM processing timed out for tag: #{tag}")
          record[@output_field] = "Error: LLM processing timed out"
        rescue => e
          log.error("Error in LLM processing: #{e.class}: #{e.message}")
          record[@output_field] = "Error: #{e.message}"
        end
        
        record
      end
    end
  end
end
