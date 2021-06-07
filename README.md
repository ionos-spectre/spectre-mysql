# Spectre MySQL

[![Build Status](https://www.travis-ci.com/cneubaur/spectre-mysql.svg?branch=master)](https://www.travis-ci.com/cneubaur/spectre-mysql)

This is a [spectre](https://bitbucket.org/cneubaur/spectre-core) module which provides MySQL access functionality to the spectre framework.

## Install

```bash
gem install spectre-mysql
```

## Configure

Add the module to your `spectre.yml`

```yml
include:
 - spectre/mysql
```

Configure some predefined MySQL connection options in your environment file

```yml
mysql:
  developer:
    host: localhost
    database: developer
    username:
    password:
```

## Usage

Adds an easy way to execute SQL queries on a MySQL database.

You can set the following properties in the `mysql` block:

| Method | Arguments | Multiple | Description |
| -------| ----------| -------- | ----------- |
| `host` | `string` | no | The hostname of the database to connec to |
| `database` | `string` | no | The database to use, when executing queries |
| `username` | `string` | no | The username to authenticate at the database |
| `password` | `string` | no | The passwort for authentication |
| `query` | `string` | yes | The queries which will be executed. Note that only the last query generates a `result` |

The result of the query can be accessed by the `result` function. It contains all rows returned by the database.

When a name is provided to `mysql`, it uses either a preconfigured connection with this name or uses the name as the database hostname.

Example:

```ruby
mysql 'localhost' do
  database 'developer'
  username 'root'
  password 'dev'

  query "INSERT INTO todos VALUES('Spook arround', false)"
  query "INSERT INTO todos VALUES('Scare some people', false)"
  query "SELECT * FROM todos"
end

expect 'two entries in database' do
  result.count.should_be 2
end

expect 'the first todo not to be completed' do
  result.first.done.should_be false
end
```

You can also preconfigure a MySQL connection in your environment file.

```yml
mysql:
  developer:
    host: localhost
    database: developer
    username:
    password:
```

and use the connection by providing the section name to the `mysql` call.

```ruby
mysql 'developer' do
  query "INSERT INTO todos VALUES('Spook arround', false)"
  query "INSERT INTO todos VALUES('Scare some people', false)"
  query "SELECT * FROM todos"
end
```

If you want to execute additional queries with the same connection as on the previous `mysql` block, you can simply ommit the `name` parameter.

```ruby
mysql do
  query "INSERT INTO todos VALUES('Rattle the chains', false)"
end
```