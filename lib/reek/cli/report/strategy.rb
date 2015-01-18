module Reek
  module Cli
    module Report
      module Strategy
        #
        # Base class for report startegies.
        # Each gathers results according to strategy chosen
        #
        class Base
          attr_reader :report_formatter, :warning_formatter, :examiners

          def initialize(report_formatter, warning_formatter, examiners)
            @report_formatter = report_formatter
            @warning_formatter = warning_formatter
            @examiners = examiners
          end

          def header(examiner)
            if show_header?(examiner)
              report_formatter.header examiner
            else
              ''
            end
          end
        end

        #
        # Lists out each examiner, even if it has no smell
        #
        class Verbose < Base
          def show_header?(_examiner)
            true
          end
        end

        #
        # Lists only smelly examiners
        #
        class Quiet < Base
          def show_header?(examiner)
            examiner.smelly?
          end
        end
      end
    end
  end
end
