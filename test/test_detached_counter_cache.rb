require_relative 'test_helper'

class DetachedCounterCacheTest < Minitest::Test
  def test_user_can_count_comments
    user = User.create

    assert_equal 0, user.comments.size
    assert_equal 0, user.comments.count
  end

  def test_counter_can_increment
    user = User.create
    user.comments.create
    assert_equal 1, user.comments.size
    assert_equal 1, user.comments.count
  end

  def test_counter_can_decrement
    user = User.create
    comment = user.comments.create
    comment.destroy
    assert_equal 0, user.comments.reload.size
    assert_equal 0, user.comments.count
  end

  def test_counter_updates_when_changing_ownership
    user = User.create
    user2 = User.create
    comment = user.comments.create
    comment.update_attributes(user_id: user2.id)
    assert_equal 0, user.comments.reload.size
    assert_equal 0, user.comments.count
  end

  def test_comments_count_counts_actual_records_from_db
    user = User.create
    ActiveRecord::Base.connection.execute("insert into comments (user_id) VALUES (#{user.id})")
    ActiveRecord::Base.connection.execute("insert into comments (user_id) VALUES (#{user.id})")

    assert_equal 0, user.comments.size
    assert_equal 2, user.comments.count
  end

  def test_comments_size_checks_detached_counter_cache
    user = User.create
    ActiveRecord::Base.connection.execute(
      "insert into users_comments_counts (user_id, count) VALUES (#{user.id}, 5)"
    )

    assert_equal 5, user.comments.size
    assert_equal 0, user.comments.count
  end
end
