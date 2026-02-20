# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module ActiveTree
  class CLI
    def self.start(argv = [])
      new(argv).run
    end

    def initialize(argv = [])
      @argv = argv
    end

    def run
      record = resolve_root_record
      state = TreeState.new(root_record: record)
      renderer = Renderer.new(state)
      input = InputHandler.new

      enter_alternate_screen
      main_loop(state, renderer, input)
    ensure
      exit_alternate_screen
    end

    private

    def main_loop(state, renderer, input)
      loop do
        $stdout.print renderer.render
        $stdout.flush

        action = input.read_action
        break if action == :quit

        dispatch(action, state)
      end
    end

    def dispatch(action, state)
      case action
      when :move_up then state.move_up
      when :move_down then state.move_down
      when :toggle_expand then state.toggle_expand
      when :select then state.select_current
      end
    end

    def resolve_root_record
      validate_argv!
      klass = resolve_model(@argv[0])
      find_record(klass, @argv[1])
    end

    def validate_argv!
      return if @argv.size >= 2

      warn "Usage: activetree <ModelName> <id>"
      warn "  e.g. activetree User 42"
      exit 1
    end

    def resolve_model(model_name)
      model_name.constantize
    rescue NameError
      warn "Error: model '#{model_name}' not found"
      exit 1
    end

    def find_record(klass, record_id)
      record = klass.find_by(id: record_id)
      return record if record

      warn "Error: #{klass.name} with id #{record_id} not found"
      exit 1
    end

    def enter_alternate_screen
      $stdout.print "\e[?1049h" # alternate screen buffer
      $stdout.print "\e[?25l"   # hide cursor
      $stdout.flush
    end

    def exit_alternate_screen
      $stdout.print "\e[?25h"   # show cursor
      $stdout.print "\e[?1049l" # restore screen
      $stdout.flush
    end
  end
end
