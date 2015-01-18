require 'rainbow'

module Reek
  module Cli
    module Report
      #
      # A report that contains the smells and smell counts following source code analysis.
      #
      class Base
        DEFAULT_FORMAT = :text
        NO_WARNINGS_COLOR = :green
        WARNINGS_COLOR = :red

        def initialize(_options = {})
          @examiners           = []
          @total_smell_count   = 0
        end

        def add_examiner(examiner)
          @total_smell_count += examiner.smells_count
          @examiners << examiner
          self
        end

        def smells?
          @total_smell_count > 0
        end

        def smells
          @examiners.map(&:smells).flatten
        end
      end

      #
      # Generates a sorted, text summary of smells in examiners
      #
      class TextReport < Base
        def initialize(options = {})
          super options
          @options = options
          @warning_formatter   = options.fetch :warning_formatter, SimpleWarningFormatter
          @report_formatter    = options.fetch :report_formatter, Formatter
          @sort_by_issue_count = options.fetch :sort_by_issue_count, false
        end

        def show
          sort_examiners if smells?
          display_summary
          display_total_smell_count
        end

        def smells
          @examiners.each_with_object([]) do |examiner, result|
            result << summarize_single_examiner(examiner)
          end
        end

        private

        def display_summary
          print smells.reject(&:empty?).join("\n")
        end

        def display_total_smell_count
          return unless @examiners.size > 1
          print "\n"
          print total_smell_count_message
        end

        def summarize_single_examiner(examiner)
          result = heading_formatter.header(examiner)
          if examiner.smelly?
            formatted_list = @report_formatter.format_list(examiner.smells,
                                                           @warning_formatter)
            result += ":\n#{formatted_list}"
          end
          result
        end

        def sort_examiners
          @examiners.sort_by!(&:smells_count).reverse! if @sort_by_issue_count
        end

        def total_smell_count_message
          colour = smells? ? WARNINGS_COLOR : NO_WARNINGS_COLOR
          s = @total_smell_count == 1 ? '' : 's'
          Rainbow("#{@total_smell_count} total warning#{s}\n").color(colour)
        end

        def heading_formatter
          @heading_formatter ||=
            @options.fetch(:heading_formatter, HeadingFormatter::Quiet).new(@report_formatter)
        end
      end

      #
      # Displays a list of smells in YAML format
      # YAML with empty array for 0 smells
      class YamlReport < Base
        def show
          print(smells.to_yaml)
        end
      end

      #
      # Saves the report as a HTML file
      #
      class HtmlReport < Base
        require 'erb'

        def show
          path = File.expand_path('../../../../../assets/html_output.html.erb',
                                  __FILE__)
          File.open('reek.html', 'w+') do |file|
            file.puts ERB.new(File.read(path)).result(binding)
          end
          print("Html file saved\n")
        end
      end
    end
  end
end
