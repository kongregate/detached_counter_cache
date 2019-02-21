ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, force: true do |t|
    t.string :name
    t.integer :likes_count, default: 0, null: false
  end

  create_table :comments, force: true do |t|
    t.integer :user_id, null: false
    t.string :content
  end

  create_table :users_comments_counts, force: true do |t|
    t.integer :user_id, null: false
    t.integer :count, default: 0, null: false
  end

  create_table :likes, force: true do |t|
    t.integer :user_id, null: false
    t.integer :count, default: 0, null: false
  end
end
