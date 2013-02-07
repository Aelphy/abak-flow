# coding : utf-8
# TODO : Написать + реализовать
require "i18n"

module Abak::Flow
  class Messages
    extend Forwardable

    attr_reader :scope, :elements

    def initialize(scope)
      init_dependences

      @scope = scope
      @elements = []
    end

    # Iterate elements from locale scope (translating online)
    #
    #
    def each
      raise ArgumentError, "No block given" unless block_given?

      elements.each do |key|
        yield translate(key)
      end
    end

    # Put item to elements
    #
    # Returns Symbol
    def push(element)
      @elements << element.to_sym
    end
    alias :<< :push

    # section header from locale scope
    #
    # Returns String
    def header
      translate :header
    end

    # Print all elements from locale scope without header
    #
    # Returns Symbol
    def to_s
    end

    # Print section header from locale scope and all elements from scope
    #
    # Returns String
    def pretty_print
    end
    alias :pp :pretty_print

    private
    def_delegators Config, :locale

    def init_dependences
      Config.init
    end

    def translate(key)
      I18n.t key, scope: scope_key
    end

    def scope_key
      [locale, scope] * "."
    end
  end
end