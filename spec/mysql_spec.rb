module Spectre
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
end

require_relative '../lib/spectre/mysql'

RSpec.describe Spectre::MySQL do
  before do
    client = double(::Mysql2::Client)
    expect(client).to receive(:close)
    expect(client).to receive(:query).with('SELECT * FROM some_table', {:cast_booleans=>true})
    allow(client).to receive(:query).and_return([{foo: 'bar'}])

    args = {
      host: 'localhost',
      username: 'developer',
      password: 'supersecure',
      database: 'test',
    }

    allow(::Mysql2::Client).to receive(:new).with(**args).and_return(client)
  end

  it 'executes a query' do
    Spectre::MySQL.mysql 'localhost' do
      username 'developer'
      password 'supersecure'
      database 'test'

      query 'SELECT * FROM some_table'
    end

    expect(Spectre::MySQL.result.length).to eq(1)
  end

  it 'executes a query with preconfig' do
    Spectre::MySQL.mysql 'example' do
      query 'SELECT * FROM some_table'
    end

    expect(Spectre::MySQL.result.length).to eq(1)
  end
end
