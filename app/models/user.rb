class User < ActiveRecord::Base
  enum account_type: [:office365]
end
