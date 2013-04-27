# coding: utf-8
require "spec_helper"

describe Abak::Flow::Git do
  subject { described_class.clone.instance }

  describe "Interface" do
    it { should respond_to :git }
    it { should respond_to :command }
    it { should respond_to :command_lines }
  end
end