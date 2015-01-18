require 'spec_helper'
require 'reek/examiner'
require 'reek/cli/report/report'

include Reek
include Reek::Cli

describe Report::HtmlReport do
  let(:instance) { Report::HtmlReport.new }

  context 'with an empty source' do
    let(:examiner) { Examiner.new('') }

    before do
      instance.add_examiner examiner
    end

    it 'has the text 0 total warnings' do
      instance.show

      file = File.expand_path('../../../../reek.html', __FILE__)
      text = File.read(file)
      File.delete(file)

      expect(text).to include('0 total warnings')
    end
  end
end
