module Abak
  module Flow
  end
end

require 'ostruct'
require 'forwardable'

require 'hub'
require 'highline'
require 'octokit'

#require 'abak-flow/extensions'
require 'abak-flow/config'
require 'abak-flow/github_client'
require 'abak-flow/pull_request'
require 'abak-flow/version'

require 'commander/import'


# New requires
# TODO Вынести в отдельный рекваер установки цветовой схемы
# HighLine.color_scheme = HighLine::SampleColorScheme.new
require 'abak-flow/project'
require 'abak-flow/config'
