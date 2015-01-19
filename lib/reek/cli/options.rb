require 'optparse'
require 'ostruct'
require 'rainbow'
require 'reek/cli/report/report'
require 'reek/cli/report/formatter'
require 'reek/cli/report/heading_formatter'
require 'reek/cli/reek_command'
require 'reek/cli/help_command'
require 'reek/cli/version_command'
require 'reek/cli/input'

module Reek
  module Cli
    #
    # Parses the command line
    #
    class Options
      include Cli::Input

      def initialize(argv)
        @argv    = argv
        @parser  = OptionParser.new
        @options = OpenStruct.new

        @options.colored             = true
        @options.report_class        = Report::TextReport
        @options.heading_formatter   = Report::HeadingFormatter::Quiet
        @options.warning_formatter   = Report::SimpleWarningFormatter
        @options.location_formatter  = Report::DefaultLocationFormatter
        @options.command_class       = ReekCommand
        @options.config_file         = nil
        @options.sort_by_issue_count = false
        @options.smells_to_detect    = []

        set_up_parser
      end

      def parse
        @parser.parse!(@argv)
        Rainbow.enabled = @options.colored
        @options.command_class.new(self)
      end

      def reporter
        @reporter ||=
          @options.report_class.new(
            warning_formatter: @options.warning_formatter.new(@options.location_formatter),
            report_formatter: Report::Formatter,
            sort_by_issue_count: @options.sort_by_issue_count,
            heading_formatter: @options.heading_formatter)
      end

      def program_name
        @program_name ||= @parser.program_name
      end

      def help_text
        @parser.to_s
      end

      def smells_to_detect
        @options.smells_to_detect
      end

      def config_file
        @options.config_file
      end

      private

      def banner
        <<-EOB.gsub(/^[ ]+/, '')
          Usage: #{program_name} [options] [files]

          Examples:

          #{program_name} lib/*.rb
          #{program_name} -q lib
          cat my_class.rb | #{program_name}

          See http://wiki.github.com/troessner/reek for detailed help.

        EOB
      end

      def set_up_parser
        @parser.banner = banner
        set_configuration_options
        set_alternative_formatter_options
        set_report_formatting_options
        set_utility_options
      end

      def set_utility_options
        @parser.separator "\nUtility options:"
        @parser.on('-h', '--help', 'Show this message') do
          @options.command_class = HelpCommand
        end
        @parser.on('-v', '--version', 'Show version') do
          @options.command_class = VersionCommand
        end
      end

      def set_configuration_options
        @parser.separator 'Configuration:'
        @parser.on('-c', '--config FILE', 'Read configuration options from FILE') do |file|
          @options.config_file = file
        end
        @parser.on('--smell SMELL', 'Detect smell SMELL (default is all enabled smells)') do |smell|
          @options.smells_to_detect << smell
        end
      end

      def set_report_formatting_options
        @parser.separator "\nText format options:"
        set_up_color_option
        set_up_verbosity_options
        set_up_location_formatting_options
        set_up_sorting_option
      end

      def set_up_color_option
        @parser.on('--[no-]color', 'Use colors for the output (this is the default)') do |opt|
          @options.colored = opt
        end
      end

      def set_up_verbosity_options
        @parser.on('-V', '--[no-]empty-headings',
                   'Show headings for smell-free source files') do |show_empty|
          @options.heading_formatter = if show_empty
                                         Report::HeadingFormatter::Verbose
                                       else
                                         Report::HeadingFormatter::Quiet
                                       end
        end

        @parser.on('-U', '--[no-]wiki-links',
                   'Show link to related Reek wiki page for each smell') do |show_links|
          @options.warning_formatter = if show_links
                                         Report::UltraVerboseWarningFormatter
                                       else
                                         Report::SimpleWarningFormatter
                                       end
        end
      end

      def set_up_location_formatting_options
        @parser.on('-n', '--[no-]line-numbers',
                   'Show line numbers in the output (this is the default)') do |show_numbers|
          @options.location_formatter = if show_numbers
                                          Report::DefaultLocationFormatter
                                        else
                                          Report::BlankLocationFormatter
                                        end
        end
        @parser.on('-s', '--single-line',
                   'Show location in editor-compatible single-line-per-smell format') do
          @options.location_formatter = Report::SingleLineLocationFormatter
        end
      end

      def set_up_sorting_option
        @parser.on('--sort SORTING',
                   'Choose a sorting method',
                   '  [i]ssue-count ("smelliest" files first)',
                   '  [n]one (default - output in processing order)') do |sorting|
                     @options.sort_by_issue_count = case sorting
                                                    when /^i/
                                                      true
                                                    else
                                                      false
                                                    end
                   end
      end

      def set_alternative_formatter_options
        @parser.separator "\nReport format:"

        @parser.on('-f', '--format FORMAT',
                   'Report smells in the given format',
                   '  [t]ext (default)',
                   '  [y]aml',
                   '  [h]tml') do |opt|
          @options.report_class = case opt
                                  when /^t/
                                    Report::TextReport
                                  when /^y/
                                    Report::YamlReport
                                  when /^h/
                                    Report::HtmlReport
                                  end
        end
      end
    end
  end
end
