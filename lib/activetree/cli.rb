# frozen_string_literal: true

module ActiveTree
  class CLI
    DISPATCH = {
      toggle_focus: :toggle_focus,
      navigate_right: :navigate_right,
      navigate_left: :navigate_left,
      move_up: :cursor_up,
      move_down: :cursor_down,
      toggle_expand: :toggle_expand,
      select: :select_current,
      make_root: :make_selected_record_root,
      toggle_field_mode: :toggle_field_mode
    }.freeze

    def self.start(argv = [])
      puts Pastel.new.magenta.bold("Starting ActiveTree v#{ActiveTree::VERSION}...")
      new(argv).run
    end

    def initialize(argv = [])
      @argv = argv
    end

    def run
      state = TreeState.new
      renderer = Renderer.new(state)
      input = InputHandler.new
      dialog_input = DialogInputHandler.new

      # Try to resolve root from CLI args
      apply_query_result(RootQuery.new(@argv[0], @argv[1]), state) if @argv.size >= 2

      begin
        enter_alternate_screen
        if state.empty?
          # Fall through to query dialog if no root node was resolved from args
          open_query_dialog(state, renderer, dialog_input)
          return unless state.root
        end
        main_loop(state, renderer, input, dialog_input)
      ensure
        exit_alternate_screen
      end
    end

    private

    def main_loop(state, renderer, input, dialog_input)
      loop do
        $stdout.print renderer.render
        $stdout.flush

        action = input.read_action
        break if action == :quit

        if action == :open_query_dialog
          open_query_dialog(state, renderer, dialog_input)
        else
          dispatch(action, state)
        end
      end
    end

    def dispatch(action, state)
      state.public_send(DISPATCH[action]) if DISPATCH[action]
    end

    def open_query_dialog(state, renderer, dialog_input)
      dialog = QueryDialog.new
      loop do
        dialog_loop(dialog, renderer, dialog_input)
        return if dialog.cancelled?

        begin
          apply_query_result(dialog.root_query, state)
          return
        rescue ArgumentError => e
          dialog.error_message = e.message
          reset_dialog_for_retry(dialog)
        end
      end
    end

    def dialog_loop(dialog, renderer, dialog_input)
      loop do
        $stdout.print renderer.render(dialog: dialog)
        $stdout.flush

        action = dialog_input.read_action
        next unless action

        case action
        when :cancel
          dialog.cancel!
        when :submit
          dialog.error_message = nil
          dialog.submit!
        when :next_field
          dialog.next_field
        when :backspace
          dialog.backspace
        when :cursor_left
          dialog.cursor_left
        when :cursor_right
          dialog.cursor_right
        when Array
          dialog.insert_char(action[1]) if action[0] == :insert
        end

        break if dialog.resolved?
      end
    end

    def apply_query_result(root_query, state)
      state.set_root_node(root_query.as_tree_node)
    end

    def reset_dialog_for_retry(dialog)
      # Reset submitted/cancelled state so dialog can be re-shown
      dialog.instance_variable_set(:@submitted, false)
      dialog.instance_variable_set(:@cancelled, false)
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
