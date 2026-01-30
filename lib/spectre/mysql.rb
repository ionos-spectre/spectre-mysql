require 'logger'
require 'mysql2'
require 'ostruct'

module Spectre
  module MySQL
    class MySqlQuery
      include Spectre::Delegate if defined? Spectre::Delegate

      def initialize query
        @__query = query
      end

      def host hostname
        @__query['host'] = hostname
      end

      def username user
        @__query['username'] = user
      end

      def password pass
        @__query['password'] = pass
      end

      def database name
        @__query['database'] = name
      end

      def query statement
        @__query['query'] = [] unless @__query.key? 'query'
        @__query['query'].append(statement)
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
        query = {}

        if !name.nil? and @config.key? name
          query.merge! @config[name]

          unless query['host']
            raise "No `host' set for MySQL client '#{name}'. Check your MySQL config in your environment."
          end

        elsif !name.nil?
          query['host'] = name
        elsif @last_conn.nil?
          raise 'No name given and there was no previous MySQL connection to use'
        end

        MySqlQuery.new(query).instance_eval(&) if block_given?

        unless name.nil?
          @last_conn = {
            host: query['host'],
            username: query['username'],
            password: query['password'],
            database: query['database'],
          }
        end

        @logger.info "Connecting to database #{query['username']}@#{query['host']}:#{query['database']}"

        client = ::Mysql2::Client.new(**@last_conn)

        res = []

        query['query']&.each do |statement|
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
