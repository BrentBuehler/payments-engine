class CreateTransactionsAndAccountsTables < ActiveRecord::Migration[6.1]
  def change
    create_table :transactions do |t|
      t.belongs_to :account # Creates an account_id column that joins to the accounts table
      t.string :transaction_type
      t.decimal :amount, precision: 15, :scale => 4
      t.boolean :is_disputed, :default => false

      t.timestamps
    end

    create_table :accounts do |t|
      t.decimal :available, precision: 15, :scale => 4
      t.decimal :held, precision: 15, :scale => 4
      t.decimal :total, precision: 15, :scale => 4
      t.boolean :is_locked, :default => false

      t.timestamps
    end
  end
end
