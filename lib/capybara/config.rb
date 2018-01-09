# frozen_string_literal: true

require 'forwardable'
require 'capybara/session/config'

module Capybara
  class Config
    extend Forwardable

    OPTIONS = %i[app reuse_server threadsafe default_wait_time server default_driver javascript_driver].freeze

    attr_accessor :app
    attr_reader :reuse_server, :threadsafe
    attr_reader :session_options
    attr_writer :default_driver, :javascript_driver

    SessionConfig::OPTIONS.each do |method|
      def_delegators :session_options, method, "#{method}="
    end

    def initialize
      @session_options = Capybara::SessionConfig.new
    end

    attr_writer :reuse_server

    def threadsafe=(bool)
      warn "Capybara.threadsafe == true is a BETA feature and may change in future minor versions" if bool
      raise "Threadsafe setting cannot be changed once a session is created" if (bool != threadsafe) && Session.instance_created?
      @threadsafe = bool
    end

    ##
    #
    # Return the proc that Capybara will call to run the Rack application.
    # The block returned receives a rack app, port, and host/ip and should run a Rack handler
    # By default, Capybara will try to run webrick.
    #
    def server
      raise ArgumentError, "Capybara#server no longer accepts a block" if block_given?
      @server
    end

    ##
    #
    # Set the server to use.
    #
    #     Capybara.server = :webrick
    #     Capybara.server = :puma, { Silent: true }
    #
    # @overload server=(name)
    #   @param [Symbol] name     Name of the server type to use
    # @overload server=([name, options])
    #   @param [Symbol] name Name of the server type to use
    #   @param [Hash] options Options to pass to the server block
    # @see register_server
    #
    def server=(name)
      name, options = *name if name.is_a? Array
      @server = if options
        proc { |app, port, host| Capybara.servers[name.to_sym].call(app, port, host, options) }
      else
        Capybara.servers[name.to_sym]
      end
    end

    ##
    #
    # @return [Symbol]    The name of the driver to use by default
    #
    def default_driver
      @default_driver || :rack_test
    end

    ##
    #
    # @return [Symbol]    The name of the driver used when JavaScript is needed
    #
    def javascript_driver
      @javascript_driver || :selenium
    end

    def deprecate(method, alternate_method, once = false)
      @deprecation_notified ||= {}
      warn "DEPRECATED: ##{method} is deprecated, please use ##{alternate_method} instead" unless once and @deprecation_notified[method]
      @deprecation_notified[method] = true
    end
  end
end
