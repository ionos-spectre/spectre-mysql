# Spectre MySQL

[![Build](https://github.com/ionos-spectre/spectre-mysql/actions/workflows/build.yml/badge.svg)](https://github.com/ionos-spectre/spectre-mysql/actions/workflows/build.yml)
[![Gem Version](https://badge.fury.io/rb/spectre-mysql.svg)](https://badge.fury.io/rb/spectre-mysql)

This is a [spectre](https://github.com/ionos-spectre/spectre-core) module which provides MySQL access functionality to the spectre framework.

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


### Troubleshoot

Did you have some trouble installing the gem `mysql2`? Doesn't suprise.

On Debian or Ubuntu it is fairly easy fix. Just execute.

```bash
sudo apt-get install libmysqlclient-dev
sudo gem install mysql2
```

Yes, there is a reason why I mentioned the _easy_ linux part. On Windows it is quite tricky... ok, not tricky, rather a pain... a pain in the a**.
A pain you should noone wish. A pain whereas even hell is a spa.

Want to go through this?

Ok, let's go. Try to install the package with `gem install mysql2` as it is intended.

```powershell
PS C:\> gem install mysql2
ERROR:  Error installing mysql2:
        The last version of mysql2 (>= 0) to support your Ruby & RubyGems was 0.5.3. Try installing it with `gem install mysql2 -v 0.5.3`
        mysql2 requires Ruby version >= 2.2, < 2.7.dev. The current ruby version is 2.7.0.0.
```

> Really? Do I have to downgrade my Ruby version?

No, fortunately not. Just get *Ruby 3.0*.

> But Ruby 3.0 is even greater?

Yes, I know. Don't ask too much. It works.

Ok, now we can install the package

```bash
gem install mysql2
```

Haha, got you! You didn't thought it is that easy, right?! Right!

As windows does not have the MySQL client libraries installed, we have to add the argument `--without-mysql-dir`, when installing. For this, we need the libs first.
Ok, easy. You might think you go to the MySQL website and get the latest 64bit MySQL libraries as a ZIP file, extract it and pass the path to the argument, right? Wrong! Good and logical idea, but it won't work. Don't even try it (or try it, if you like it. I don't care).

Maybe you are smarter than me, know some C stuff and think "you are stupid, you need to use the 32bit version of the libs". Ok cool. Problem 1: There are no 32bit version of the latest MySQL libraries. Ok, let's get the next best version with 32bit libraries and try again.

Wohooo! It has been installed! Yeah! Let's get going and try it. Let's start `irb` and `require` the package.

```powershell
PS C:\> irb
irb(main):001:0> require 'mysql2'
Traceback (most recent call last):
       10: from C:/Tools/Ruby30-x64/bin/irb.cmd:31:in `<main>'
        9: from C:/Tools/Ruby30-x64/bin/irb.cmd:31:in `load'
        8: from C:/Tools/Ruby30-x64/lib/ruby/gems/3.0.0/gems/irb-1.3.0/exe/irb:11:in `<top (required)>'
        7: from (irb):1:in `<main>'
        6: from <internal:C:/Tools/Ruby30-x64/lib/ruby/3.0.0/rubygems/core_ext/kernel_require.rb>:149:in `require'
        5: from <internal:C:/Tools/Ruby30-x64/lib/ruby/3.0.0/rubygems/core_ext/kernel_require.rb>:160:in `rescue in require'
        4: from <internal:C:/Tools/Ruby30-x64/lib/ruby/3.0.0/rubygems/core_ext/kernel_require.rb>:160:in `require'
        3: from C:/Tools/Ruby30-x64/lib/ruby/gems/3.0.0/gems/mysql2-0.5.3/lib/mysql2.rb:36:in `<top (required)>'
        2: from <internal:C:/Tools/Ruby30-x64/lib/ruby/3.0.0/rubygems/core_ext/kernel_require.rb>:85:in `require'
        1: from <internal:C:/Tools/Ruby30-x64/lib/ruby/3.0.0/rubygems/core_ext/kernel_require.rb>:85:in `require'
RuntimeError (Incorrect MySQL client library version! This gem was compiled for 5.7.32 but the client library is 10.5.5.)
```

> You are kidding, right?

*Wrong!*. Really? You thought it would be *that* easy?!

"Ok, got it". Cool, but what's about this client library `10.5.5` version? Isn't MySQL only at `8.0.32` (it was at that point I wrote this)? Yes, it is, but who said we speak about MySQL? Ever heard about *MariaDB*, you dip sh**? Yes you got it, we need the MariaDB connector libs.

Go to https://mariadb.com/downloads/#connectors and download version `3.1.15`. Yes, *64bit* is fine. Install it and finally install the `mysql2` gem.
"But `3.1.15` is not the latest one?". Did I stutter? Trust me, use this version. The latest one won't do.

```bash
gem install mysql2 --platform=ruby -- '--with-mysql-dir="C:\Program Files\MariaDB\MariaDB Connector C 64-bit"'
```

Congratulations! You made it! Sorry for the harsh words, but this is really cracking me up.
