CONFIG = {
  'mysql' => {
    'example' => {
      'host' => 'localhost',
      'username' => 'developer',
      'password' => 'supersecure',
      'database' => 'test',
    },
  },
}

require_relative '../lib/spectre/mysql'

RSpec.describe Spectre::MySQL do
  let(:logger) { Logger.new(StringIO.new) }
  let(:mysql_client) { double(Mysql2::Client) }

  before do
    allow(mysql_client).to receive(:close)
    allow(mysql_client).to receive(:query).and_return([{ foo: 'bar' }])
  end

  def stub_connect(**args)
    expect(Mysql2::Client).to receive(:new).with(**args).and_return(mysql_client)
  end

  it 'executes a query' do
    stub_connect(
      host: 'localhost',
      username: 'developer',
      password: 'supersecure',
      database: 'test',
      ssl_mode: :required
    )
    expect(mysql_client).to receive(:close)
    expect(mysql_client).to receive(:query).with('SELECT * FROM some_table', { cast: false, cast_booleans: false })

    client = Spectre::MySQL::Client.new(CONFIG, logger)
    client.mysql 'localhost' do
      username 'developer'
      password 'supersecure'
      database 'test'

      query 'SELECT * FROM some_table'
    end

    expect(client.result.length).to eq(1)
  end

  it 'executes a query with preconfig' do
    stub_connect(
      host: 'localhost',
      username: 'developer',
      password: 'supersecure',
      database: 'test',
      ssl_mode: :required
    )
    expect(mysql_client).to receive(:close)
    expect(mysql_client).to receive(:query).with('SELECT * FROM some_table', { cast: false, cast_booleans: false })

    client = Spectre::MySQL::Client.new(CONFIG, logger)
    client.mysql 'example' do
      query 'SELECT * FROM some_table'
    end

    expect(client.result.length).to eq(1)
  end

  it 'passes ssl_mode set via the DSL to mysql2' do
    stub_connect(
      host: 'localhost',
      username: 'developer',
      password: 'supersecure',
      database: 'test',
      ssl_mode: :disabled
    )
    expect(mysql_client).to receive(:close)
    expect(mysql_client).to receive(:query).with('SELECT 1', { cast: false, cast_booleans: false })

    client = Spectre::MySQL::Client.new(CONFIG, logger)
    client.mysql 'localhost' do
      username 'developer'
      password 'supersecure'
      database 'test'
      ssl :disabled

      query 'SELECT 1'
    end
  end

  it 'coerces a string ssl value from YAML config to a symbol' do
    config = {
      'mysql' => {
        'example' => {
          'host' => 'localhost',
          'username' => 'developer',
          'password' => 'supersecure',
          'database' => 'test',
          'ssl' => 'verify_ca',
        },
      },
    }

    stub_connect(
      host: 'localhost',
      username: 'developer',
      password: 'supersecure',
      database: 'test',
      ssl_mode: :verify_ca
    )
    expect(mysql_client).to receive(:close)

    Spectre::MySQL::Client.new(config, logger).mysql 'example' do
      query 'SELECT 1'
    end
  end

  it 'closes the connection even when a query raises' do
    stub_connect(
      host: 'localhost',
      username: 'developer',
      password: 'supersecure',
      database: 'test',
      ssl_mode: :required
    )
    expect(mysql_client).to receive(:query).and_raise(StandardError.new('boom'))
    expect(mysql_client).to receive(:close)

    client = Spectre::MySQL::Client.new(CONFIG, logger)
    expect do
      client.mysql 'localhost' do
        username 'developer'
        password 'supersecure'
        database 'test'

        query 'SELECT broken'
      end
    end.to raise_error(StandardError, 'boom')
  end
end
