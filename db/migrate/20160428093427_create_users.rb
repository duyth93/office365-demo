class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :access_token, { limit: 10000 }
      t.string :refresh_token, { limit: 2000 }
      t.string :expires_on
      t.integer :account_type
    end
  end
end
