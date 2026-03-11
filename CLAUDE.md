# FlowEngine CLI — Project Instructions

## Project Overview

**flowengine-cli** is a TTY terminal adapter for the [flowengine](https://github.com/kigster/flowengine) core gem. It renders multi-step wizard flows as interactive ANSI terminal prompts and outputs collected answers as JSON.

- **Core gem** (`flowengine` >= 0.3.1): DSL, rule evaluation, engine runtime, LLM integration. Zero UI dependencies.
- **This gem** (`flowengine-cli`): Dry::CLI commands, TTY::Prompt rendering, flow file loading, JSON output.

## Key Architecture

```
lib/flowengine/cli/
  commands/
    run.rb              # Main interactive wizard command
    graph.rb            # Mermaid diagram export
    validate_flow.rb    # Flow definition validation
    version.rb          # Version printing
  commands.rb           # Dry::CLI registry
  flow_loader.rb        # Loads .rb flow definitions
  renderer.rb           # Maps Node types to TTY::Prompt widgets
  ui_helper.rb          # TTY::Box, Pastel, screen helpers
  version.rb            # VERSION constant
```

## Error Handling

All error classes live under `FlowEngine::Errors::` namespace (since flowengine 0.3.1):
- `FlowEngine::Errors::Error` — base error
- `FlowEngine::Errors::SensitiveDataError` — PII detected in introduction
- `FlowEngine::Errors::LLMError` — LLM API failures
- `FlowEngine::Errors::ValidationError` — introduction validation failures

## LLM Integration

The `run` command auto-detects LLM provider via `FlowEngine::LLM.auto_client` with env vars checked in order: `ANTHROPIC_API_KEY` > `OPENAI_API_KEY` > `GEMINI_API_KEY`. If no key is found, the wizard runs all steps without pre-filling. LLM failures degrade gracefully — the wizard never crashes due to LLM issues.

## Development Commands

```bash
just test              # bundle check + rspec + rubocop
just run <file>        # Run a flow interactively
just validate <file>   # Validate a flow definition
just graph <file>      # Export Mermaid diagram
just format            # rubocop -a + auto-gen-config
just lint              # rubocop only
just doc               # YARD docs
```

## Testing

- Framework: RSpec with `rspec-its` for compact property assertions
- Mocks: TTY::Prompt is mocked via `instance_double`; `$stdout` is suppressed
- Coverage: SimpleCov enforced at 90% minimum
- Run: `bundle exec rspec --format documentation`

## Conventions

- Ruby 4.0.1 via rbenv (`eval "$(rbenv init -)"` before any Ruby command)
- 2-space indentation
- `frozen_string_literal: true` in all files
- RuboCop config in `.rubocop.yml` (AbcSize disabled)
- Specs use `let(:var)` / `let!(:var)`, `rspec-its` one-liners preferred
- Commits: imperative mood, 50-char subject, atomic changes

## Important Notes

- The `select_options` helper in `renderer.rb` handles both array options and hash `option_labels` (key => label display)
- `FlowEngine::Introduction` is a data class with `label`, `placeholder`, `maxlength` attributes
- The `render_introduction` method collects multiline text; empty line terminates input
- Step numbering is 1-based: `engine.history.length + 1`
- API keys can be loaded via `.env` file through direnv (`.envrc` sources `.env`)

## Examples

Eight example flows in `examples/`:
- `01_hello_world.rb` through `08_tax_preparer.rb`
- `08_tax_preparer.rb` is the most complex (18 steps with introduction + LLM support)
- All examples validate cleanly with `just validate`
