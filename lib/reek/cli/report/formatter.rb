require 'reek/cli/report/location_formatter'

module Reek
  module Cli
    module Report
      module Formatter
        def self.format_list(warnings, formatter = SimpleWarningFormatter.new)
          warnings.map do |warning|
            "  #{formatter.format warning}"
          end.join("\n")
        end

        def self.header(examiner)
          count = examiner.smells_count
          result = Rainbow("#{examiner.description} -- ").cyan +
                   Rainbow("#{count} warning").yellow
          result += Rainbow('s').yellow unless count == 1
          result
        end
      end

      class SimpleWarningFormatter
        def initialize
          @location_formatter = BlankLocationFormatter
        end

        def format(warning)
          "#{@location_formatter.format(warning)}#{base_format(warning)}"
        end

        private

        def base_format(warning)
          "#{warning.context} #{warning.message} (#{warning.smell_type})"
        end
      end

      class WarningFormatterWithLineNumbers < SimpleWarningFormatter
        def initialize
          @location_formatter = DefaultLocationFormatter
        end
      end

      class SingleLineWarningFormatter
        def initialize
          @location_formatter = SingleLineLocationFormatter
        end
      end

      class UltraVerboseWarningFormattter < WarningFormatterWithLineNumbers
        BASE_URL_FOR_HELP_LINK = 'https://github.com/troessner/reek/wiki/'

        def format(warning)
          "#{super} " \
          "[#{explanatory_link(warning)}]"
        end

        def explanatory_link(warning)
          "#{BASE_URL_FOR_HELP_LINK}#{class_name_to_param(warning.smell_type)}"
        end

        def class_name_to_param(name)
          name.split(/(?=[A-Z])/).join('-')
        end
      end
    end
  end
end
