class AddLoginAndCountryToUser < ActiveRecord::Migration
  def self.up
    add_column "users", "login", :string
    add_column "users", "country_id", :integer
  end

  def self.down
    remove_column "users", "country_id"
    remove_column "users", "login"
  end
end
