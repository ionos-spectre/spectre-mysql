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
        elsif @last_conn
          config['host']     = @last_conn[:host]
          config['username'] = @last_conn[:username]
          config['password'] = @last_conn[:password]
          config['database'] = @last_conn[:database]
          config['ssl']      = @last_conn[:ssl_mode]
        else
          raise 'No name given and there was no previous MySQL connection to use'
        end

        MySqlQuery.new(config).instance_eval(&) if block_given?

        @last_conn = {
          host: config['host'],
          username: config['username'],
          password: config['password'],
          database: config['database'],
          ssl_mode: (config['ssl'] || :required).to_sym,
        }

        @logger.info "Connecting to database #{@last_conn[:username]}@#{@last_conn[:host]}:#{@last_conn[:database]}"

        client = ::Mysql2::Client.new(**@last_conn)

        begin
          res = nil

          config['query']&.each do |statement|
            @logger.info("Executing statement '#{statement}'")
            # cast: false returns all columns as strings — Spectre tests treat values as opaque,
            # and this avoids mysql2's BigDecimal/Date casting failures on driver-level mismatches.
            res = client.query(statement, cast: false, cast_booleans: false)
          end

          @result = res.map { |row| OpenStruct.new(row) } if res
        ensure
          client.close
        end
      end

      def result
        raise 'No MySQL query has been executed yet' unless @result

        @result
      end
    end
  end

  Engine.register(MySQL::Client, :mysql, :result) if defined? Engine
end
