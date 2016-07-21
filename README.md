# detached_counter_cache

[![Build Status](https://travis-ci.org/kongregate/detached_counter_cache.png?branch=master)](https://travis-ci.org/kongregate/detached_counter_cache)

detached_counter_cache is a tool for keeping track of a counter cache that lives in its own table. It works with Rails 4.1 and 4.2, and only MySQL.

## Usage

For example, with `User` and `Comment` classes you may want to cache `user.comments.size`, but don't want to create `comments_count` on `User`.

```ruby
class User < ActiveRecord::Base
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :user, detached_counter_cache: true
end
```

You'll need to generate a migration that creates your counter cache table.

```ruby
create_table :users_comments_counts, force: true do |t|
  t.integer :user_id, null: false
  t.integer :count, default: 0, null: false
end
```

## Contributors

* [stopdropandrew](https://github.com/stopdropandrew)
* [drewchandler](https://github.com/drewchandler)
* [duncanbeevers](https://github.com/duncanbeevers)

## License

MIT License
