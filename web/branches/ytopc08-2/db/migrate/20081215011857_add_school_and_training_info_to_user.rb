class AddSchoolAndTrainingInfoToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :school, :string
    add_column :users, :trained_at_ipst, :boolean
  end

  def self.down
    remove_column :users, :trained_at_ipst
    remove_column :users, :school
  end
end
