require 'optparse'
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

      attr_reader :config_file, :smells_to_detect

      def initialize(argv)
        @argv                = argv
        @parser              = OptionParser.new
        @colored             = true
        @report_class        = Report::TextReport
        @heading_formatter   = Report::HeadingFormatter::Quiet
        @warning_formatter   = Report::SimpleWarningFormatter
        @location_formatter  = Report::DefaultLocationFormatter
        @command_class       = ReekCommand
        @config_file         = nil
        @sort_by_issue_count = false
        @smells_to_detect    = []
        set_options
      end

      def parse
        @parser.parse!(@argv)
        Rainbow.enabled = @colored
        @command_class.new(self)
      end

      def reporter
        @reporter ||=
          @report_class.new(warning_formatter: @warning_formatter.new(@location_formatter),
                            report_formatter: Report::Formatter,
                            sort_by_issue_count: @sort_by_issue_count,
                            heading_formatter: @heading_formatter)
      end

      def program_name
        @program_name ||= @parser.program_name
      end

      def help_text
        @parser.to_s
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

      def set_options
        @parser.banner = banner
        set_configuration_options
        set_alternative_formatter_options
        set_report_formatting_options
        set_utility_options
      end

      def set_utility_options
        @parser.separator "\nUtility options:"
        @parser.on('-h', '--help', 'Show this message') do
          @command_class = HelpCommand
        end
        @parser.on('-v', '--version', 'Show version') do
          @command_class = VersionCommand
        end
      end

      def set_configuration_options
        @parser.separator 'Configuration:'
        @parser.on('-c', '--config FILE', 'Read configuration options from FILE') do |file|
          @config_file = file
        end
        @parser.on('--smell SMELL', 'Detect smell SMELL (default is all enabled smells)') do |smell|
          @smells_to_detect << smell
        end
      end

      def set_report_formatting_options
        @parser.separator "\nText format options:"
        @parser.on('--[no-]color', 'Use colors for the output (this is the default)') do |opt|
          @colored = opt
        end
        @parser.on('-V', '--[no-]empty-headings',
                   'Show headings for smell-free source files') do |opt|
          @heading_formatter = if opt
                                 Report::HeadingFormatter::Verbose
                               else
                                 Report::HeadingFormatter::Quiet
                               end
        end

        @parser.on('-U', '--wiki-links',
                   'Show link to related Reek wiki page for each smell') do
          @warning_formatter = Report::UltraVerboseWarningFormatter
        end

        @parser.on('-n', '--[no-]line-numbers',
                   'Show line numbers in the output (this is the default)') do |opt|
          if opt
            @location_formatter = Report::DefaultLocationFormatter
          else
            @location_formatter = Report::BlankLocationFormatter
          end
        end
        @parser.on('-s', '--single-line',
                   'Show location in editor-compatible single-line-per-smell format') do
          @location_formatter = Report::SingleLineLocationFormatter
        end

        @parser.on('--sort SORTING',
                   'Choose a sorting method',
                   '  [i]ssue-count ("smelliest" files first)',
                   '  [n]one (default - output in processing order)') do |opt|
          @sort_by_issue_count = case opt
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
          @report_class = case opt
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
