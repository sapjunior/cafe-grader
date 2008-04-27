class CreateSites < ActiveRecord::Migration
  def self.up
    create_table :sites do |t|
      t.column :country_id, :integer
      t.column :name, :string
      t.column :login, :string
      t.column :password, :string

      t.timestamps
    end
  end

  def self.down
    drop_table :sites
  end
end
