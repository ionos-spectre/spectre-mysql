require 'logger'
require 'mysql2'
require 'spectre'
require 'ostruct'


module Spectre
  module MySQL
    class MySqlQuery < Spectre::DslClass
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

    class << self
      @@config = defined?(Spectre::CONFIG) ? Spectre::CONFIG['mysql'] : {}
      @@logger = defined?(Spectre.logger) ? Spectre.logger : Logger.new(STDOUT)

      @@result = nil
      @@last_conn = nil

      def mysql name = nil, &block
        query = {}

        if name != nil and @@config.key? name
          query.merge! @@config[name]

          raise "No `host' set for MySQL client '#{name}'. Check your MySQL config in your environment." unless query['host']

        elsif name != nil
          query['host'] = name
        elsif @@last_conn == nil
          raise 'No name given and there was no previous MySQL connection to use'
        end

        MySqlQuery.new(query).instance_eval(&block) if block_given?

        if name != nil
          @@last_conn = {
            host: query['host'],
            username: query['username'],
            password: query['password'],
            database: query['database'],
          }
        end

        @@logger.info "Connecting to database #{query['username']}@#{query['host']}:#{query['database']}"

        client = ::Mysql2::Client.new(**@@last_conn)

        res = []

        query['query'].each do |statement|
          @@logger.info 'Executing statement "' + statement + '"'
          res = client.query(statement, cast_booleans: true)
        end if query['query']

        @@result = res.map { |row| OpenStruct.new row } if res

        client.close
      end

      def result
        raise 'No MySQL query has been executed yet' unless @@result

        @@result
      end
    end
  end
end

%i{mysql}.each do |method|
  define_method(method) do |*args, &block|
    Spectre::MySQL.send(method, *args, &block)
  end
end
