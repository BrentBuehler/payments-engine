class Account < ApplicationRecord
    has_many :transactions

    def handle_deposit_transaction(row)
        self.available += row[:amount]
        self.total += row[:amount]
        self.save
        self.transactions.create(id: row[:tx], transaction_type: row[:type], amount: row[:amount], is_disputed: false)
    end

    def handle_withdrawal_transaction(row)
        self.available -= row[:amount]
        self.total -= row[:amount]
        self.save
        self.transactions.create(id: row[:tx], transaction_type: row[:type], amount: row[:amount], is_disputed: false)
    end

    def handle_transaction_dispute(transaction)
        transaction.mark_as_disputed
        self.available -= transaction.amount
        self.held += transaction.amount
        self.save
    end

    def handle_transaction_dispute_resolution(transaction)
        transaction.resolve_dispute
        self.available += transaction.amount
        self.held -= transaction.amount
        self.save
    end

    def handle_transaction_chargeback(transaction)
        transaction.resolve_dispute
        self.held -= transaction.amount
        self.total -= transaction.amount
        self.is_locked = true
        self.save
    end
end
