# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # This cop checks how the *when*s of a *case* expression
      # are indented in relation to its *case* or *end* keyword.
      #
      # It will register a separate offense for each misaligned *when*.
      class CaseIndentation < Cop
        include AutocorrectAlignment
        include ConfigurableEnforcedStyle

        MSG = 'Indent `when` %s `%s`.'.freeze

        def on_case(case_node)
          return if case_node.single_line?

          case_node.each_when do |when_node|
            check_when(when_node)
          end
        end

        private

        def check_when(when_node)
          when_column = when_node.loc.keyword.column
          base_column = base_column(when_node.parent, style)

          if when_column == base_column + indentation_width
            correct_style_detected
          else
            incorrect_style(when_node)
          end
        end

        def indent_one_step?
          cop_config['IndentOneStep']
        end

        def indentation_width
          indent_one_step? ? configured_indentation_width : 0
        end

        def incorrect_style(when_node)
          when_column = when_node.loc.keyword.column
          base_column = base_column(when_node.parent, alternative_style)

          add_offense(when_node, :keyword, message(style)) do
            if when_column == base_column
              opposite_style_detected
            else
              unrecognized_style_detected
            end
          end
        end

        def message(base)
          depth = indent_one_step? ? 'one step more than' : 'as deep as'

          format(MSG, depth, base)
        end

        def base_column(case_node, base)
          case base
          when :case then case_node.location.keyword.column
          when :end  then case_node.location.end.column
          end
        end

        def autocorrect(node)
          whitespace = whitespace_range(node)

          return false unless whitespace.source.strip.empty?

          lambda do |corrector|
            corrector.replace(whitespace, replacement(node))
          end
        end

        def whitespace_range(node)
          when_column = node.location.keyword.column
          begin_pos = node.loc.keyword.begin_pos

          range_between(begin_pos - when_column, begin_pos)
        end

        def replacement(node)
          case_node = node.each_ancestor(:case).first
          base_type = cop_config[style_parameter_name] == 'end' ? :end : :case

          column = base_column(case_node, base_type)
          column += indentation_width

          ' ' * column
        end
      end
    end
  end
end
