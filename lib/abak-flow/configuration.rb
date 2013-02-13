# coding: utf-8
#
# Module for access to global abak-flow gem config
# recieved from .git config and environment
#
# Auto generated methods: oauth_user, oauth_token, proxy_server
#
# TODO : Проверять что атрибут из конфига валиден
# TODO : Переименовать модуль
#
# Example
#
#   Abak::Flow::Configuration.oauth_user #=> Strech
#
module Abak::Flow
  module Configuration

    # TODO : Уметь запоминать, что инициализация уже была
    def self.init
      return unless need_initialize?

      reset_variables

      init_git_configuration
      init_environment_configuration

      setup_locale

      @@initialized = true
    end

    def self.params
      @@params.dup
    end

    protected
    def self.init_git_configuration
      git_config = [git.config["abak-flow.oauth-user"],
                    git.config["abak-flow.oauth-token"],
                    git.config["abak-flow.proxy-server"],
                    git.config["abak-flow.locale"] || "en"]

      @@params = Params.new(*git_config)
    end

    def self.init_environment_configuration
      return unless params.proxy_server.nil?

      @@params.proxy_server = environment_http_proxy
    end

    def self.check_requirements
      conditions = [params.oauth_user, params.oauth_token].map(&:to_s)

      if conditions.any? { |c| c.empty? }
        raise Exception, "You have incorrect git config. Check [abak-flow] section"
      end
    end

    def self.git
      Git.git
    end

    def self.environment_http_proxy
      ENV['http_proxy'] || ENV['HTTP_PROXY']
    end

    class Params < Struct.new(:oauth_user, :oauth_token, :proxy_server, :locale)
      def to_hash
        Hash[members.map { |m| [m, self.send(m)] }]
      end
    end

    Params.members.each do |name|
      self.class.send :define_method, name, -> { @@params[name.to_sym] }
    end

    private
    def self.initialized
      @@initialized
    end

    def self.need_initialize?
      initialized != true
    end

    def self.reset_variables
      @@params = {}
      @@initialized = false
    end
    reset_variables

    def self.setup_locale
      I18n.load_path += Dir.glob(File.join File.dirname(__FILE__), "locales/*.{rb,yml}")
      I18n.locale = locale
    end
  end
end