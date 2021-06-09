require 'spectre/mysql'

RSpec.describe Spectre::MySQL do
  it 'executes a query' do
    hostname = 'localhost'
    select_statement = 'SELECT * FROM some_table'

    client = double(::Mysql2::Client)
    expect(client).to receive(:close)
    expect(client).to receive(:query).with(select_statement, {:cast_booleans=>true})
    allow(client).to receive(:query).and_return([{foo: 'bar'}])

    args = {
      host: hostname,
      username: 'developer',
      password: 'supersecure',
      database: 'test',
    }

    allow(::Mysql2::Client).to receive(:new).with(**args).and_return(client)

    Spectre::MySQL.mysql hostname do
      username args[:username]
      password args[:password]
      database args[:database]

      query select_statement
    end

    expect(Spectre::MySQL.result.length).to eq(1)
  end
end