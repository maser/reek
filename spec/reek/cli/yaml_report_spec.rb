require 'spec_helper'
require 'reek/examiner'
require 'reek/cli/report/report'
require 'reek/cli/report/formatter'

include Reek
include Reek::Cli

describe Report::YamlReport do
  let(:instance) { Report::YamlReport.new }

  context 'empty source' do
    let(:examiner) { Examiner.new('') }

    before do
      instance.add_examiner examiner
    end

    it 'prints empty yaml' do
      result = capture_output_stream { instance.show }
      expect(result).to match(/^--- \[\]\n.*$/)
    end
  end
end
