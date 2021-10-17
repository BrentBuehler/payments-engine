class TransactionsProcessor

    def initialize(file_path)
        @file_path = file_path
    end

    def process
        CSV.foreach(@file_path, headers: true, header_converters: :symbol) do |row|
            row[:amount] = row[:amount].to_f
            account = Account.find_by(id: row[:client])

            case row[:type]
            when 'deposit'
                if account.present?
                    account.handle_deposit_transaction(row) unless account.is_locked                
                else
                    account = Account.create(id: row[:client], available: row[:amount], held: 0, total: row[:amount])
                    account.transactions.create(id: row[:tx], transaction_type: row[:type], amount: row[:amount], is_disputed: false)
                end
            when 'withdrawal'
                account.handle_withdrawal_transaction(row) unless !account.present? || account.is_locked || (account.available - row[:amount] < 0)
            when 'dispute'
                transaction = Transaction.find_by(id: row[:tx])
                account.handle_transaction_dispute(transaction) unless !transaction.present?
            when 'resolve'
                transaction = Transaction.find_by(id: row[:tx])
                account.handle_transaction_dispute_resolution(transaction) unless !transaction.present? || !transaction.is_disputed
            when 'chargeback'
                transaction = Transaction.find_by(id: row[:tx])
                account.handle_transaction_chargeback(transaction) unless !transaction.present? || !transaction.is_disputed
            end
        end

        puts 'client, available, held, total, locked'
        Account.all.each { |account| puts [account.id, strip_trailing_zeros(account.available), strip_trailing_zeros(account.held), strip_trailing_zeros(account.total), account.is_locked].join(', ')}
        
        # Comment the below out if accounts and transaction records should carry over to consecutive processes.
        # You can also execute 'rake clear_database' to clear the database once
        Account.destroy_all
        Transaction.destroy_all
    end

    def strip_trailing_zeros(amount)
        amount.to_s.sub(/\.?0+$/, '')
    end
end
