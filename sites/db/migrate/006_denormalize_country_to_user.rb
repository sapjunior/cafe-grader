class DenormalizeCountryToUser < ActiveRecord::Migration
  def self.up
    add_column "users", "country_id", :integer

    User.reset_column_information
    User.find(:all).each do |user|
      if user.site!=nil
        user.country_id = user.site.country_id
        user.save
      end
    end
  end

  def self.down
    remove_column "users", "country_id"
  end
end
