# coding : utf-8
require "i18n"

# TODO : Нужен простой метод, для перевода без скоупа
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
    # Returns nothing
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
      return "" if elements.empty?

      all_elements = []
      elements.each_with_index do |key, index|
        all_elements << "#{index + 1}. #{translate(key)}"
      end

      all_elements * "\n"
    end

    # Print section header from locale scope and all elements from scope
    #
    # Returns String
    def pretty_print
      return "" if elements.empty?

      "#{header}\n\n#{to_s}"
    end
    alias :pp :pretty_print

    def translate(key)
      I18n.t key, scope: scope
    end
    alias :t :translate

    private
    def_delegators Configuration, :locale
    def_delegators :elements, :empty?

    def init_dependences
      Configuration.init
    end
  end
end