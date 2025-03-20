# fluent-plugin-llm-generate

[Fluentd](https://fluentd.org/) filter plugin to process text with Large Language Models (LLMs) using Ollama.

## Overview

This plugin sends text from your Fluentd logs to a local Ollama instance for LLM processing. It adds AI-generated text to your records, enabling capabilities like:

- Text summarization
- Entity extraction
- Sentiment analysis
- Content moderation
- Translation
- And more, depending on the model and prompt used

## Installation

### Requirements

- Ruby 3.4.1 or higher
- [Ollama](https://ollama.ai/) installed and running
- Fluentd v0.14.10 or higher
- The `llmalfr` gem for Ollama integration

### RubyGems

```
$ gem install fluent-plugin-llm-generate
```

### Bundler

Add the following line to your Gemfile:

```ruby
gem 'fluent-plugin-llm-generate'
```

And then execute:

```
$ bundle
```

## Configuration

### Filter Configuration

```
<filter your.tag.here>
  @type llm_generate
  
  # Ollama model name (optional)
  model_name hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest
  
  # Ollama API URL (optional)
  api_url http://localhost:11434/api
  
  # Prompt for the LLM
  prompt Summarize this text in one sentence.
  
  # Input field to process (optional)
  input_field message
  
  # Output field to store results (optional)
  output_field llm_output
  
  # Custom LLM options as JSON (optional)
  {"temperature":0.6,"top_p":0.88,"top_k":40,"num_predict":512,"repeat_penalty":1.2,"presence_penalty":0.2,"frequency_penalty":0.2,"stop":["\n\n","。\n"],"seed":0}
  
  # Timeout in seconds for LLM processing (optional)
  timeout 300
</filter>
```

### Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| model_name | string | The Ollama model name to use | hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest |
| api_url | string | The Ollama API URL | http://localhost:11434/api |
| prompt | string | The prompt/instruction for the LLM | (required) |
| input_field | string | The field in the record to extract context from | message |
| output_field | string | The field in the record to store the LLM result | llm_output |
| options_json | string | JSON string with custom LLM options | {"temperature":0.6,"top_p":0.88,"top_k":40,"num_predict":512,"repeat_penalty":1.2,"presence_penalty":0.2,"frequency_penalty":0.2,"stop":["\n\n","。\n"],"seed":0} |
| timeout | integer | Timeout in seconds for LLM processing | 300 |

## LLM Options

You can customize the LLM behavior using the `options_json` parameter. Here are some common options:

```json
{
  "temperature": 0.6,           // Controls randomness (0.0-1.0)
  "top_p": 0.88,                // Nucleus sampling parameter
  "top_k": 40,                  // Limits vocabulary choices
  "num_predict": 512,           // Maximum tokens to generate
  "repeat_penalty": 1.2,        // Penalize repetitions
  "presence_penalty": 0.2,      // Discourage repeating topics
  "frequency_penalty": 0.2,     // Add variety in word choice
  "stop": ["\n\n", "。\n"],     // Stop sequences
  "seed": 0                     // Random seed (-1 for random)
}
```

## Input/Output

### Input Record Fields

The plugin processes the field specified by `input_field` in the incoming record.

### Output Record Fields

The plugin adds or modifies the field specified by `output_field` in the output record with the generated LLM response.

## Error Handling

The plugin implements minimal error handling:

- If the input field is missing from the record, the record passes through unchanged
- Any exceptions during LLM processing are propagated to the caller
- It's the caller's responsibility to handle exceptions appropriately

## Examples

### Summarize log messages

```
<filter app.logs>
  @type llm_generate
  model_name hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest
  api_url http://localhost:11434/api
  prompt Summarize this log entry in one short sentence.
  input_field log
  output_field summary
  options_json {"temperature":0.6,"top_p":0.88,"top_k":40,"num_predict":512,"repeat_penalty":1.2,"presence_penalty":0.2,"frequency_penalty":0.2,"stop":["\n\n","。\n"],"seed":0}
</filter>
```

### Translate user feedback

```
<filter feedback.user>
  @type llm_generate
  model_name hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest
  api_url http://localhost:11434/api
  prompt Translate the following user feedback to English.
  input_field text
  output_field english_text
  options_json {"temperature":0.6,"top_p":0.88,"top_k":40,"num_predict":512,"repeat_penalty":1.2,"presence_penalty":0.2,"frequency_penalty":0.2,"stop":["\n\n","。\n"],"seed":0}
</filter>
```

### Extract key entities from customer support tickets

```
<filter support.tickets>
  @type llm_generate
  model_name hf.co/elyza/Llama-3-ELYZA-JP-8B-GGUF:latest
  api_url http://localhost:11434/api
  prompt Extract the following entities from this support ticket: product_name, issue_type, severity (high, medium, low), customer_sentiment (positive, neutral, negative).
  input_field description
  output_field entities
  options_json {"temperature":0.6,"top_p":0.88,"top_k":40,"num_predict":512,"repeat_penalty":1.2,"presence_penalty":0.2,"frequency_penalty":0.2,"stop":["\n\n","。\n"],"seed":0}
</filter>
```

## Performance Considerations

- LLM processing can be resource-intensive and time-consuming
- Consider implementing your own timeout mechanism at the Fluentd level if needed
- Consider using separate worker threads for Fluentd if processing large volumes of records

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake test` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bash0C7/fluent-plugin-llm-generate.
