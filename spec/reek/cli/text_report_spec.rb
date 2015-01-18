require 'spec_helper'
require 'reek/examiner'
require 'reek/cli/report/report'
require 'reek/cli/report/formatter'
require 'rainbow'

include Reek
include Reek::Cli

describe Report::TextReport do
  let(:report_options) do
    {
      warning_formatter: Report::SimpleWarningFormatter,
      report_formatter: Report::Formatter,
      heading_formatter: Report::HeadingFormatter::Quiet
    }
  end
  let(:instance) { Report::TextReport.new report_options }

  context 'with a single empty source' do
    let(:examiner) { Examiner.new('') }

    it 'has an empty quiet_report' do
      instance.add_examiner(examiner)
      expect { instance.show }.to_not output.to_stdout
    end
  end

  context 'with non smelly files' do
    let(:result) { capture_output_stream { @rpt.show } }

    before :each do
      @rpt = instance
      @rpt.add_examiner(Examiner.new('def simple() puts "a" end'))
      @rpt.add_examiner(Examiner.new('def simple() puts "a" end'))
    end

    context 'with colors disabled' do
      before :each do
        Rainbow.enabled = false
      end

      it 'shows total of 0 warnings' do
        expect(result).to end_with "0 total warnings\n"
      end
    end

    context 'with colors enabled' do
      before :each do
        Rainbow.enabled = true
      end

      it 'has a footer in color' do
        expect(result).to end_with "\e[32m0 total warnings\n\e[0m"
      end
    end
  end

  context 'with a couple of smells' do
    before :each do
      @rpt = Report::TextReport.new report_options
      @rpt.add_examiner(Examiner.new('def simple(a) a[3] end'))
      @rpt.add_examiner(Examiner.new('def simple(a) a[3] end'))
    end

    context 'with colors disabled' do
      let(:result) { capture_output_stream { @rpt.show } }

      before :each do
        Rainbow.enabled = false
      end

      it 'has a heading' do
        expect(result).to match('string -- 2 warnings')
      end

      it 'should mention every smell name' do
        expect(result).to include('UncommunicativeParameterName')
        expect(result).to include('FeatureEnvy')
      end
    end

    context 'with colors enabled' do
      let(:result) { capture_output_stream { @rpt.show } }

      before :each do
        Rainbow.enabled = true
      end

      it 'has a header in color' do
        expect(result).
          to start_with "\e[36mstring -- \e[0m\e[33m2 warning\e[0m\e[33ms\e[0m"
      end

      it 'has a footer in color' do
        expect(result).to end_with "\e[31m4 total warnings\n\e[0m"
      end
    end
  end
end
