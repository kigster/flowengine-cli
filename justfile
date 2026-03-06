set shell := ["bash", "-c"]

set dotenv-load

[no-exit-message]
recipes:
    @just --choose

# Boot the app
test:
    @echo "Ensuring bundle install is up to date..."
    @bundle check ||  bundle install -j 12
    @echo "Running specs..."
    @bundle exec rspec --format documentation
    @echo "Running rubocop..."
    @bundle exec rubocop

# Setup Ruby dependencies
setup-ruby:
    #!/usr/bin/env bash
    [[ -d ~/.rbenv ]] || git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    [[ -d ~/.rbenv/plugins/ruby-build ]] || git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    cd ~/.rbenv/plugins/ruby-build && git pull && cd - >/dev/null
    echo -n "Checking if Ruby $(cat .ruby-version | tr -d '\n') is already installed..."
    rbenv install -s "$(cat .ruby-version | tr -d '\n')" >/dev/null 2>&1 && echo "yes" || echo "it wasn't, but now it is"
    bundle check || bundle install -j 12

# Setup NodeJS dependencies with Volta
setup-node:
    @bash -c "command -v volta > dev/null 2>&1 || brew install volta"
    @volta install node
    @volta install yarn

# Setup everything
setup: setup-node setup-ruby

cli *ARGS:
    ./cli {{ARGS}}

# Run a flow interactively: just run examples/01_hello_world.rb
run file *ARGS:
    @bundle exec exe/flowengine-cli run {{file}} {{ARGS}}

# Export a flow as a Mermaid diagram: just graph examples/07_loan_application.rb
graph file *ARGS:
    @bundle exec exe/flowengine-cli graph {{file}} {{ARGS}}

# Validate a flow definition: just validate examples/04_event_registration.rb
validate file:
    @bundle exec exe/flowengine-cli validate {{file}}

# List available example flows
examples:
    #!/usr/bin/env bash
    echo "Available examples (by complexity):"
    echo ""
    for f in examples/*.rb; do
      head -3 "$f" | grep '# Example' | sed 's/^# /  /'
      echo "    just run $f"
      echo ""
    done

# Formats minor syntax issues and writes the rest into a TODO file
format:
    @bundle exec rubocop -a
    @bundle exec rubocop --auto-gen-config

# Run all linters, in this case just rubocop
lint: 
    @bundle exec rubocop

# Generates YARD documentation into the ./doc folder, and opens ./doc/index.html
doc:
    @rake doc
    @open doc/index.html

check-all: lint test

