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
        @warning_formatter   = Report::WarningFormatterWithLineNumbers.new
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
        @reporter ||= @report_class.new(warning_formatter: @warning_formatter,
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
        set_common_options
        set_configuration_options
        set_report_formatting_options
      end

      def set_common_options
        @parser.separator 'Common options:'
        @parser.on('-h', '--help', 'Show this message') do
          @command_class = HelpCommand
        end
        @parser.on('-v', '--version', 'Show version') do
          @command_class = VersionCommand
        end
      end

      def set_configuration_options
        @parser.separator "\nConfiguration:"
        @parser.on('-c', '--config FILE', 'Read configuration options from FILE') do |file|
          @config_file = file
        end
        @parser.on('--smell SMELL', 'Detect smell SMELL (default is all enabled smells)') do |smell|
          @smells_to_detect << smell
        end
      end

      def set_report_formatting_options
        @parser.separator "\nReport formatting:"
        @parser.on('-o', '--[no-]color',
                   'Use colors for the output (this is the default)') do |opt|
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

        @parser.on('-U', '--ultra-verbose', 'Be as explanatory as possible') do
          @warning_formatter = Report::UltraVerboseWarningFormattter.new
        end

        @parser.on('-n', '--[no-]line-numbers',
                   'Show line numbers in the output (this is the default)') do |opt|
          if opt
            @warning_formatter = Report::WarningFormatterWithLineNumbers.new
          else
            @warning_formatter = Report::SimpleWarningFormatter.new
          end
        end
        @parser.on('-S', '--sort-by-issue-count',
                   'Sort by "issue-count", listing the "smelliest" files first') do
          @sort_by_issue_count = true
        end

        set_alternative_formatter_options
      end

      def set_alternative_formatter_options
        @parser.on('-s', '--single-line',
                   'Report smells in editor-compatible single-line-per-warning format') do
          @warning_formatter = Report::SingleLineWarningFormatter.new
        end
        @parser.on('-y', '--yaml', 'Report smells in YAML format') do
          @report_class = Report::YamlReport
        end
        @parser.on('-H', '--html', 'Report smells in HTML format') do
          @report_class = Report::HtmlReport
        end
      end
    end
  end
end
