class User < ActiveRecord::Base
  has_many :comments
  has_many :likes
end

class Comment < ActiveRecord::Base
  belongs_to :user, detached_counter_cache: true
end

class Like < ActiveRecord::Base
  belongs_to :user, counter_cache: true
end
