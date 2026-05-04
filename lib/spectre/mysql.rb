require 'logger'
require 'mysql2'
require 'ostruct'

module Spectre
  module MySQL
    class MySqlQuery
      include Spectre::Delegate if defined? Spectre::Delegate

      def initialize config
        @__config = config
      end

      def host hostname
        @__config['host'] = hostname
      end

      def username user
        @__config['username'] = user
      end

      def password pass
        @__config['password'] = pass
      end

      def database name
        @__config['database'] = name
      end

      def ssl mode
        @__config['ssl'] = mode
      end

      def query statement
        @__config['query'] = [] unless @__config.key? 'query'
        @__config['query'].append(statement)
      end
    end

    class Client
      include Spectre::Delegate if defined? Spectre::Delegate

      def initialize config, logger
        @config = config['mysql'] || {}
        @logger = logger

        @result = nil
        @last_conn = nil
      end

      def mysql(name = nil, &)
        config = {}

        if !name.nil? and @config.key? name
          config.merge! @config[name]

          unless config['host']
            raise "No `host' set for MySQL client '#{name}'. Check your MySQL config in your environment."
          end

        elsif !name.nil?
          config['host'] = name
        elsif @last_conn.nil?
          raise 'No name given and there was no previous MySQL connection to use'
        end

        MySqlQuery.new(config).instance_eval(&) if block_given?

        unless name.nil?
          @last_conn = {
            host: config['host'],
            username: config['username'],
            password: config['password'],
            database: config['database'],
            ssl_mode: config['ssl'] || :required
          }
        end

        @logger.info "Connecting to database #{config['username']}@#{config['host']}:#{config['database']}"

        client = ::Mysql2::Client.new(**@last_conn)

        res = []

        config['query']&.each do |statement|
          @logger.info("Executing statement '#{statement}'")

          # FIXED: Disable automatic casting to prevent BigDecimal errors
          # This prevents mysql2 from trying to cast VARCHAR columns to BigDecimal
          res = client.query(statement, cast: false, cast_booleans: false)
        end

        # FIXED: Safely convert rows to OpenStruct with error handling
        # If casting is still problematic, we catch the error and retry with manual conversion
        if res
          begin
            @result = res.map { |row| OpenStruct.new row }
          rescue ArgumentError => e
            raise unless e.message.include?('BigDecimal')

            @logger.warn "BigDecimal casting error detected, falling back to safe conversion: #{e.message}"
            # Manually convert each row, skipping problematic values
            @result = res.map do |row|
              safe_row = {}
              row.each do |key, value|
                safe_row[key] = begin
                  value.to_s
                rescue StandardError
                  value
                end
              end
              OpenStruct.new(safe_row)
            end
          end
        end

        client.close
      end

      def result
        raise 'No MySQL query has been executed yet' unless @result

        @result
      end
    end
  end

  Engine.register(MySQL::Client, :mysql, :result) if defined? Engine
end
