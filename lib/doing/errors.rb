# frozen_string_literal: true

module Doing
  module Errors
    class UserCancelled < ::StandardError
      def initialize(msg = 'Cancelled', topic = 'Exited:')
        Doing.logger.output_results
        Doing.logger.log_now(:warn, topic, msg)
        Process.exit 1
      end
    end

    class EmptyInput < ::StandardError
      def initialize(msg = 'No input', topic = 'Exited:')
        Doing.logger.output_results
        Doing.logger.log_now(:warn, topic, msg)
      end
    end

    class DoingStandardError < ::StandardError
      def initialize(msg = '')
        Doing.logger.output_results

        super
      end
    end

    class WrongCommand < ::StandardError
      def initialize(msg = 'wrong command', topic: 'Error:')
        Doing.logger.warn(topic, msg)

        super(msg)
      end
    end

    class DoingRuntimeError < ::RuntimeError
      def initialize(msg = 'Runtime Error', exit_code = nil, topic: 'Error:')
        Doing.logger.output_results
        Doing.logger.log_now(:error, topic, msg)

        Process.exit exit_code if exit_code
      end
    end

    class NoResults < ::StandardError
      def initialize(msg = 'No results', topic = 'Exited:')
        Doing.logger.output_results
        Doing.logger.log_now(:warn, topic, msg)
        Process.exit 0

      end
    end

    class DoingNoTraceError < ::StandardError
      def initialize(msg = nil, level: nil, topic: 'Error:', exit_code: 1)
        level ||= :error
        Doing.logger.output_results
        if msg
          Doing.logger.log_now(level, topic, msg)
        end

        Process.exit exit_code
      end
    end

    class HistoryLimitError < DoingNoTraceError
      def initialize(msg, exit_code = 24)
        super(msg, level: :error, topic: 'History:', exit_code: exit_code)
      end
    end

    class MissingBackupFile < DoingNoTraceError
      def initialize(msg, exit_code = 26)
        super(msg, level: :error, topic: 'History:', exit_code: exit_code)
      end
    end

    class InvalidPlugin < DoingRuntimeError
      def initialize(kind = 'output', msg = nil)
        super(%(Invalid #{kind} type (#{msg})), 128, topic: 'Invalid:')
      end
    end

    class PluginException < ::StandardError
      attr_reader :plugin

      def initialize(msg = 'Plugin error', type = nil, plugin = nil)
        @plugin = plugin || 'Unknown Plugin'

        type ||= 'Unknown'
        @type = case type.to_s
                when /^i/
                  'Import plugin'
                when /^e/
                  'Export plugin'
                else
                  type.to_s
                end

        msg = "(#{@type}: #{@plugin}) #{msg}"

        Doing.logger.log_now(:error, 'Plugin:', msg)
      end
    end

    HookUnavailable = Class.new(PluginException)
    InvalidPluginType = Class.new(PluginException)
    PluginUncallable = Class.new(PluginException)

    InvalidArgument = Class.new(DoingRuntimeError)
    MissingArgument = Class.new(DoingRuntimeError)
    MissingFile = Class.new(DoingRuntimeError)
    MissingEditor = Class.new(DoingRuntimeError)
    NonInteractive = Class.new(StandardError)

    NoEntryError = Class.new(DoingRuntimeError)

    InvalidTimeExpression = Class.new(DoingRuntimeError)
    InvalidSection = Class.new(DoingRuntimeError)
    InvalidView = Class.new(DoingRuntimeError)

    ItemNotFound = Class.new(DoingRuntimeError)
    # FatalException = Class.new(::RuntimeError)
    # InvalidPluginName = Class.new(FatalException)
  end
end
