# coding: utf-8
require "spec_helper"
require "abak-flow/github_client"

describe Abak::Flow::GithubClient do
  let(:described_class) { Abak::Flow::GithubClient }

  it { described_class.must_respond_to :connection }
end