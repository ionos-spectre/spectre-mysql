# Spectre MySQL Module - Usage Guide

## What is the MySQL Module?

The Spectre MySQL module allows you to test MySQL database operations. You can execute SQL queries and validate results, making it useful for testing data integrity, stored procedures, and database-driven applications.

## Installation

Add to your `spectre.yml`:

```yaml
modules:
  - spectre-mysql
```

## Configuration

Configure your MySQL databases in your environment file:

```yaml
# environments/development.env.yml
mysql:
  app-database:
    host: localhost
    username: testuser
    password: testpass
    database: myapp_test
    ssl: required        # optional, defaults to :required
  
  analytics-db:
    host: analytics.example.com
    username: readonly
    password: readonly123
    database: analytics
    ssl: disabled        # disable SSL for legacy/internal databases
```

### SSL Modes

The `ssl` option controls the connection's SSL/TLS behavior. Supported values match the `mysql2` gem's `ssl_mode`:

| Mode | Description |
|------|-------------|
| `disabled` | No SSL/TLS used |
| `preferred` | Use SSL if available, fall back to plaintext |
| `required` | **(default)** Require SSL, fail if not available |
| `verify_ca` | Require SSL and validate the server's CA certificate |
| `verify_identity` | Require SSL, validate CA, and verify hostname |

If `ssl` is not specified, the connection defaults to `:required`. Set `ssl: disabled` for environments where SSL is unavailable.

---

## Basic Database Operations

### Simple Query

```ruby
it 'retrieves user count' do
  mysql 'app-database' do
    query 'SELECT COUNT(*) as count FROM users'
  end
  
  user_count = result.first.count
  info "Total users: #{user_count}"
  
  assert user_count.to be_greater_than 0
end
```

### Selecting Data

```ruby
it 'retrieves user records' do
  mysql 'app-database' do
    query 'SELECT id, name, email FROM users LIMIT 10'
  end
  
  users = result
  
  info "Retrieved #{users.length} users"
  
  users.each do |user|
    info "User: #{user.name} (#{user.email})"
  end
  
  expect result.length.to be 10
end
```

### Inserting Data

```ruby
it 'inserts new user' do
  test_email = "test_#{uuid}@example.com"
  
  mysql 'app-database' do
    query "INSERT INTO users (name, email, created_at) 
           VALUES ('Test User', '#{test_email}', NOW())"
  end
  
  # Verify insertion
  mysql do
    query "SELECT * FROM users WHERE email = '#{test_email}'"
  end
  
  assert result.length.to be 1
  expect result.first.name.to be 'Test User'
  
  bag.user_id = result.first.id
end
```

### Updating Data

```ruby
it 'updates user information' do
  mysql 'app-database' do
    query "UPDATE users SET name = 'Updated Name' WHERE id = #{bag.user_id}"
  end
  
  # Verify update
  mysql do
    query "SELECT name FROM users WHERE id = #{bag.user_id}"
  end
  
  assert result.first.name.to be 'Updated Name'
end
```

### Deleting Data

```ruby
it 'deletes user' do
  mysql 'app-database' do
    query "DELETE FROM users WHERE id = #{bag.user_id}"
  end
  
  # Verify deletion
  mysql do
    query "SELECT * FROM users WHERE id = #{bag.user_id}"
  end
  
  assert result.length.to be 0
end
```

---

## Multiple Queries

You can execute multiple queries in sequence:

```ruby
it 'performs multiple operations' do
  mysql 'app-database' do
    query 'CREATE TEMPORARY TABLE temp_users (id INT, name VARCHAR(100))'
    query "INSERT INTO temp_users VALUES (1, 'Alice')"
    query "INSERT INTO temp_users VALUES (2, 'Bob')"
    query 'SELECT * FROM temp_users'
  end
  
  # Result contains data from the last query
  assert result.length.to be 2
  expect result.first.name.to be 'Alice'
end
```

---

## Working with Results

### Accessing First Row

```ruby
it 'gets single record' do
  mysql 'app-database' do
    query 'SELECT * FROM settings WHERE key = "app_version"'
  end
  
  setting = result.first
  
  info "App version: #{setting.value}"
  expect setting.value.to_not be nil
end
```

### Iterating Over Results

```ruby
it 'processes all records' do
  mysql 'app-database' do
    query 'SELECT id, username, status FROM users WHERE status = "active"'
  end
  
  active_users = result
  
  active_users.each do |user|
    info "Active user: #{user.username} (ID: #{user.id})"
    
    # Validate each user
    expect user.username.to_not be_empty
    expect user.status.to be 'active'
  end
  
  info "Total active users: #{active_users.length}"
end
```

### Accessing Column Values

```ruby
it 'extracts specific columns' do
  mysql 'app-database' do
    query 'SELECT id, name, email, age FROM users WHERE id = 1'
  end
  
  user = result.first
  
  # Access columns using dot notation
  user_id = user.id
  user_name = user.name
  user_email = user.email
  user_age = user.age
  
  info "User: #{user_name}, Email: #{user_email}, Age: #{user_age}"
  
  property user_data: {
    id: user_id,
    name: user_name,
    email: user_email
  }
end
```

---

## Inline Connection Overrides

You can override connection settings (including SSL mode) directly inside the `mysql` block. This is useful for ad-hoc connections or when overriding a single setting from the environment config.

```ruby
it 'connects to a one-off host with SSL disabled' do
  mysql 'app-database' do
    host     'legacy.internal'
    username 'reader'
    password 'secret'
    database 'legacy_db'
    ssl      :disabled
    query    'SELECT * FROM legacy_records LIMIT 5'
  end

  info "Retrieved #{result.length} legacy records"
end
```

Available DSL methods inside the `mysql` block:

| Method | Purpose |
|--------|---------|
| `host(value)` | Override the hostname |
| `username(value)` | Override the username |
| `password(value)` | Override the password |
| `database(value)` | Override the database name |
| `ssl(mode)` | Override the SSL mode (see SSL Modes table above) |
| `query(statement)` | Append a SQL statement to execute |

---

## Reusing Database Connection

After initial connection, you can execute queries without specifying the database name:

```ruby
it 'reuses database connection' do
  # First query - specify database
  mysql 'app-database' do
    query 'SELECT * FROM users WHERE id = 1'
  end
  
  bag.user = result.first
  
  # Subsequent queries - reuse connection
  mysql do
    query "SELECT * FROM orders WHERE user_id = #{bag.user.id}"
  end
  
  orders = result
  
  info "User #{bag.user.name} has #{orders.length} orders"
end
```

---

## Complete Database Test Example

```ruby
describe 'User Database Operations' do
  setup do
    bag.test_email = "test_#{uuid}@example.com"
    bag.test_user_id = nil
  end
  
  teardown do
    # Clean up test data
    if bag.test_user_id
      mysql 'app-database' do
        query "DELETE FROM users WHERE id = #{bag.test_user_id}"
      end
    end
  end
  
  it 'performs full user lifecycle' do
    # CREATE
    mysql 'app-database' do
      query "INSERT INTO users (name, email, status, created_at) 
             VALUES ('Test User', '#{bag.test_email}', 'pending', NOW())"
    end
    
    # Get inserted user  ID
    mysql do
      query "SELECT id FROM users WHERE email = '#{bag.test_email}'"
    end
    
    bag.test_user_id = result.first.id
    info "Created user with ID: #{bag.test_user_id}"
    
    # READ
    mysql do
      query "SELECT * FROM users WHERE id = #{bag.test_user_id}"
    end
    
    user = result.first
    assert user.email.to be bag.test_email
    assert user.status.to be 'pending'
    
    # UPDATE
    mysql do
      query "UPDATE users SET status = 'active' WHERE id = #{bag.test_user_id}"
    end
    
    # Verify update
    mysql do
      query "SELECT status FROM users WHERE id = #{bag.test_user_id}"
    end
    
    assert result.first.status.to be 'active'
    
    # DELETE (handled in teardown)
    info 'User lifecycle test completed'
  end
end
```

---

## Common Use Cases

### 1. Testing Data Integrity

```ruby
it 'validates user email uniqueness' do
  email = 'duplicate@example.com'
  
  # Insert first user
  mysql 'app-database' do
    query "INSERT INTO users (email, name) VALUES ('#{email}', 'User 1')"
  end
  
  # Attempt to insert duplicate (should fail)
  observe 'duplicate email insertion' do
    mysql do
      query "INSERT INTO users (email, name) VALUES ('#{email}', 'User 2')"
    end
  end
  
  # Should have failed due to unique constraint
  assert success?.to be false
  
  # Verify only one user with that email exists
  mysql do
    query "SELECT COUNT(*) as count FROM users WHERE email = '#{email}'"
  end
  
  assert result.first.count.to be 1
end
```

### 2. Testing Database Triggers

```ruby
it 'verifies audit trigger creates log entry' do
  mysql 'app-database' do
    query "UPDATE users SET status = 'inactive' WHERE id = 123"
  end
  
  # Check audit log
  mysql do
    query "SELECT * FROM audit_log WHERE user_id = 123 ORDER BY created_at DESC LIMIT 1"
  end
  
  audit_entry = result.first
  
  expect audit_entry.action.to be 'UPDATE'
  expect audit_entry.table_name.to be 'users'
  info "Audit log created: #{audit_entry.action} on #{audit_entry.table_name}"
end
```

### 3. Testing Stored Procedures

```ruby
it 'calls stored procedure' do
  mysql 'app-database' do
    query 'CALL calculate_user_stats(123)'
  end
  
  stats = result.first
  
  info "User stats - Orders: #{stats.order_count}, Total: $#{stats.total_spent}"
  
  expect stats.order_count.to be_greater_than 0
end
```

### 4. Testing Data Aggregation

```ruby
it 'calculates order statistics' do
  mysql 'app-database' do
    query <<~SQL
      SELECT 
        COUNT(*) as total_orders,
        SUM(total) as total_revenue,
        AVG(total) as avg_order_value
      FROM orders
      WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    SQL
  end
  
  stats = result.first
  
  info "Last 30 days:"
  info "  Total orders: #{stats.total_orders}"
  info "  Total revenue: $#{stats.total_revenue}"
  info "  Average order: $#{stats.avg_order_value}"
  
  property monthly_stats: {
    orders: stats.total_orders,
    revenue: stats.total_revenue
  }
end
```

### 5. Testing Data Migration

```ruby
describe 'Data Migration' do
  it 'migrates user data to new schema' do
    # Read from old schema
    mysql 'app-database' do
      query 'SELECT * FROM old_users LIMIT 100'
    end
    
    old_users = result
    
    # Migrate to new schema
    old_users.each do |old_user|
      mysql do
        query <<~SQL
          INSERT INTO users (legacy_id, name, email, status)
          VALUES (#{old_user.id}, '#{old_user.username}', '#{old_user.email_address}', 'active')
        SQL
      end
    end
    
    # Verify migration
    mysql do
      query 'SELECT COUNT(*) as count FROM users WHERE legacy_id IS NOT NULL'
    end
    
    migrated_count = result.first.count
    
    assert migrated_count.to be old_users.length
    info "Successfully migrated #{migrated_count} users"
  end
end
```

### 6. Testing Joins and Complex Queries

```ruby
it 'retrieves user orders with details' do
  mysql 'app-database' do
    query <<~SQL
      SELECT 
        u.id as user_id,
        u.name as user_name,
        o.id as order_id,
        o.total as order_total,
        o.status as order_status
      FROM users u
      INNER JOIN orders o ON u.id = o.user_id
      WHERE u.id = 123
      ORDER BY o.created_at DESC
    SQL
  end
  
  user_orders = result
  
  expect user_orders.length.to be_greater_than 0
  
  first_order = user_orders.first
  info "User: #{first_order.user_name}"
  info "Latest order: ##{first_order.order_id} - $#{first_order.order_total}"
end
```

---

## Tips and Best Practices

### 1. Always Clean Up Test Data

```ruby
teardown do
  if bag.test_ids
    ids = bag.test_ids.join(',')
    mysql 'app-database' do
      query "DELETE FROM users WHERE id IN (#{ids})"
    end
  end
end
```

### 2. Use Prepared Statement Approach

```ruby
# Avoid SQL injection by escaping values
email = "user@example.com"
name = "O'Brien"  # Contains single quote

# Escape special characters
safe_name = name.gsub("'", "''")

mysql 'app-database' do
  query "INSERT INTO users (name, email) VALUES ('#{safe_name}', '#{email}')"
end
```

### 3. Validate Empty Results

```ruby
it 'handles no results' do
  mysql 'app-database' do
    query "SELECT * FROM users WHERE id = 9999999"
  end
  
  if result.empty?
    info 'No user found (expected)'
  else
    info "Found #{result.length} users"
  end
  
  assert result.length.to be 0
end
```

### 4. Test Database Connection

```ruby
it 'verifies database connectivity', tags: [:smoke] do
  mysql 'app-database' do
    query 'SELECT 1 as connected'
  end
  
  assert result.first.connected.to be 1
  info 'Database connection successful'
end
```

### 5. Use Transactions for Complex Tests

```ruby
it 'performs complex operation in transaction' do
  mysql 'app-database' do
    query 'START TRANSACTION'
    
    query "INSERT INTO users (name) VALUES ('Test')"
    query "INSERT INTO audit_log (action) VALUES ('user_created')"
    
    # If all successful
    query 'COMMIT'
    
    # Or rollback on error
    # query 'ROLLBACK'
  end
end
```

---

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to database  
**Solution**:
- Verify host, username, password in environment config
- Check if database is accessible from your network
- Ensure MySQL user has proper permissions

### Empty Results

**Problem**: Query returns no data  
**Solution**:
- Verify the query syntax is correct
- Check if data exists in the database
- Ensure you're querying the correct database/table

### Query Errors

**Problem**: SQL query fails  
**Solution**:
- Check SQL syntax
- Verify table and column names exist
- Check for SQL injection characters
- Look at Spectre logs for detailed error messages

---

## Summary

The MySQL module provides methods to:

✅ Execute SQL queries (SELECT, INSERT, UPDATE, DELETE)  
✅ Retrieve and process query results  
✅ Perform complex database operations  
✅ Test stored procedures and triggers  
✅ Validate data integrity  
✅ Run multiple queries in sequence  

Use this module to test any MySQL database operations, including:
- Data validation
- CRUD operations
- Stored procedures
- Database triggers
- Data migrations
- Reporting queries
