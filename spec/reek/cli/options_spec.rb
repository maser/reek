require 'spec_helper'

require 'reek/cli/options'

describe Reek::Cli::Options do
  let(:instance) { Reek::Cli::Options.new([]) }

  describe '#reporter' do
    it 'returns a Report::TextReport instance by default' do
      expect(instance.reporter).to be_instance_of Reek::Cli::Report::TextReport
    end
  end
end
