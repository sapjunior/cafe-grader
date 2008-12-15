class AddProvinceToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :province, :string
  end

  def self.down
    remove_column :users, :province
  end
end
