class CreateRates < ActiveRecord::Migration[5.1]
  def change
    create_table :rates do |t|
      t.string :exchange
      t.float :bid
      t.float :ask
      t.integer :time

      t.timestamps
    end
  end
end
