require 'rails_helper'

describe TransactionsProcessor do
    let(:test_file_path) { 'spec/test_csvs/test_transactions.csv' } 
    let(:transactions_processor) { TransactionsProcessor.new(test_file_path) }
    let(:output_headers) { 'client, available, held, total, locked' }
    
    after do
        File.delete(test_file_path)
    end

    it 'outputs multiple account balances and clears the database after each process' do
        transactions = [
            { 'type' => 'deposit', 'client' => '1', 'tx' => '1','amount' => '5' },
            { 'type' => 'deposit', 'client' => '2', 'tx' => '2', 'amount' => '10' },
            { 'type' => 'deposit', 'client' => '3', 'tx' => '3', 'amount' => '15' },
            { 'type' => 'deposit', 'client' => '4', 'tx' => '4', 'amount' => '20' }
        ]
        generate_test_csv(transactions)

        account1_output = '1, 5, 0, 5, false'
        account2_output = '2, 10, 0, 10, false'
        account3_output = '3, 15, 0, 15, false'
        account4_output = '4, 20, 0, 20, false'
        expect(STDOUT).to receive(:puts).with(output_headers)
        expect(STDOUT).to receive(:puts).with(account1_output)
        expect(STDOUT).to receive(:puts).with(account2_output)
        expect(STDOUT).to receive(:puts).with(account3_output)
        expect(STDOUT).to receive(:puts).with(account4_output)
        transactions_processor.process
        
        expect(Account.count).to eq 0
        expect(Transaction.count).to eq 0
    end

    it 'rounds the returned account balances to 4 decimal places' do
        transactions = [
            { 'type' => 'deposit', 'client' => '1', 'tx' => '1','amount' => '5000.0123456789' },
            { 'type' => 'deposit', 'client' => '1', 'tx' => '2','amount' => '5000.0123456789' },
            { 'type' => 'dispute', 'client' => '1', 'tx' => '2' }
        ]
        generate_test_csv(transactions)

        account_output = '1, 5000.0123, 5000.0123, 10000.0246, false'
        expect(STDOUT).to receive(:puts).with(output_headers)
        expect(STDOUT).to receive(:puts).with(account_output)
        transactions_processor.process
    end

    context 'the type is a deposit' do
        it 'adds the transaction amount to the available and total account balances' do
            transactions = [
                { 'type' => 'deposit', 'client' => '1', 'tx' => '1','amount' => '5' },
                { 'type' => 'deposit', 'client' => '1', 'tx' => '2', 'amount' => '10' }
            ]
            generate_test_csv(transactions)

            account_output = '1, 15, 0, 15, false'
            expect(STDOUT).to receive(:puts).with(output_headers)
            expect(STDOUT).to receive(:puts).with(account_output)
            transactions_processor.process
        end

        it 'does not process the deposit if the account is locked' do
            transactions = [
                { 'type' => 'deposit', 'client' => '1', 'tx' => '1','amount' => '5' },
                { 'type' => 'dispute', 'client' => '1', 'tx' => '1' }, 
                { 'type' => 'chargeback', 'client' => '1', 'tx' => '1' }, 
                { 'type' => 'deposit', 'client' => '1', 'tx' => '2','amount' => '5' }
            ]
            generate_test_csv(transactions)

            account_output = '1, 0, 0, 0, true'
            expect(STDOUT).to receive(:puts).with(output_headers)
            expect(STDOUT).to receive(:puts).with(account_output)
            transactions_processor.process
        end
    end

    context 'the type is a withdrawal' do
        it 'subtracts the transaction amount from the available and total account balances' do
            transactions = [
                { 'type' => 'deposit', 'client' => '1', 'tx' => '1','amount' => '5' },
                { 'type' => 'withdrawal', 'client' => '1', 'tx' => '2', 'amount' => '5' }
            ]
            generate_test_csv(transactions)

            account_output = '1, 0, 0, 0, false'
            expect(STDOUT).to receive(:puts).with(output_headers)
            expect(STDOUT).to receive(:puts).with(account_output)
            transactions_processor.process
        end 

        it 'does not process the withdrawal if the account is locked' do
            transactions = [
                { 'type' => 'deposit', 'client' => '1', 'tx' => '1','amount' => '5' },
                { 'type' => 'deposit', 'client' => '1', 'tx' => '2','amount' => '10' },
                { 'type' => 'dispute', 'client' => '1', 'tx' => '1' }, 
                { 'type' => 'chargeback', 'client' => '1', 'tx' => '1' },
                { 'type' => 'withdrawal', 'client' => '1', 'tx' => '3', 'amount' => '10' }
            ]
            generate_test_csv(transactions)

            account_output = '1, 10, 0, 10, true'
            expect(STDOUT).to receive(:puts).with(output_headers)
            expect(STDOUT).to receive(:puts).with(account_output)
            transactions_processor.process
        end

        it 'does not process the withdrawal if the account has insufficient funds' do
            transactions = [
                { 'type' => 'deposit', 'client' => '1', 'tx' => '1','amount' => '5' },
                { 'type' => 'withdrawal', 'client' => '1', 'tx' => '2', 'amount' => '10' }
            ]
            generate_test_csv(transactions)

            account_output = '1, 5, 0, 5, false'
            expect(STDOUT).to receive(:puts).with(output_headers)
            expect(STDOUT).to receive(:puts).with(account_output)
            transactions_processor.process
        end
    end


    context 'the type is a dispute' do
        it 'subtracts the available amount and adds to the held amount on the account' do
            transactions = [
                { 'type' => 'deposit', 'client' => '1', 'tx' => '1','amount' => '5' },
                { 'type' => 'dispute', 'client' => '1', 'tx' => '1' }
            ]
            generate_test_csv(transactions)

            account_output = '1, 0, 5, 5, false'
            expect(STDOUT).to receive(:puts).with(output_headers)
            expect(STDOUT).to receive(:puts).with(account_output)
            transactions_processor.process
        end

        it 'does not process a dispute if the transaction does not exist' do
            transactions = [
                { 'type' => 'deposit', 'client' => '1', 'tx' => '1','amount' => '5' },
                { 'type' => 'dispute', 'client' => '1', 'tx' => '2' }
            ]
            generate_test_csv(transactions)

            account_output = '1, 5, 0, 5, false'
            expect(STDOUT).to receive(:puts).with(output_headers)
            expect(STDOUT).to receive(:puts).with(account_output)
            transactions_processor.process
        end
    end

    context 'the type is a resolve' do
        it 'adds back the available amount and reduces held amount on the account' do
            transactions = [
                { 'type' => 'deposit', 'client' => '1', 'tx' => '1','amount' => '5' },
                { 'type' => 'dispute', 'client' => '1', 'tx' => '1' },
                { 'type' => 'resolve', 'client' => '1', 'tx' => '1' }
            ]
            generate_test_csv(transactions)

            account_output = '1, 5, 0, 5, false'
            expect(STDOUT).to receive(:puts).with(output_headers)
            expect(STDOUT).to receive(:puts).with(account_output)
            transactions_processor.process
        end

        it 'does not process a resolve if the transaction is not in dispute' do
            transactions = [
                { 'type' => 'deposit', 'client' => '1', 'tx' => '1','amount' => '5' },
                { 'type' => 'resolve', 'client' => '1', 'tx' => '1' }
            ]
            generate_test_csv(transactions)

            account_output = '1, 5, 0, 5, false'
            expect(STDOUT).to receive(:puts).with(output_headers)
            expect(STDOUT).to receive(:puts).with(account_output)
            transactions_processor.process
        end
    
        it 'does not process a resolve if the transaction does not exist' do
            transactions = [
                { 'type' => 'deposit', 'client' => '1', 'tx' => '1','amount' => '5' },
                { 'type' => 'resolve', 'client' => '1', 'tx' => '2' }
            ]
            generate_test_csv(transactions)

            account_output = '1, 5, 0, 5, false'
            expect(STDOUT).to receive(:puts).with(output_headers)
            expect(STDOUT).to receive(:puts).with(account_output)
            transactions_processor.process
        end
    end

    context 'the type is a chargeback' do
        it 'subtracts the held and total balances from the account and marks the account as locked' do
            transactions = [
                { 'type' => 'deposit', 'client' => '1', 'tx' => '1','amount' => '5' },
                { 'type' => 'dispute', 'client' => '1', 'tx' => '1' },
                { 'type' => 'chargeback', 'client' => '1', 'tx' => '1' }
            ]
            generate_test_csv(transactions)

            account_output = '1, 0, 0, 0, true'
            expect(STDOUT).to receive(:puts).with(output_headers)
            expect(STDOUT).to receive(:puts).with(account_output)
            transactions_processor.process
        end

        it 'does not process a chargeback if the transaction is not in dispute' do
            transactions = [
                { 'type' => 'deposit', 'client' => '1', 'tx' => '1','amount' => '5' },
                { 'type' => 'chargeback', 'client' => '1', 'tx' => '1' }
            ]
            generate_test_csv(transactions)

            account_output = '1, 5, 0, 5, false'
            expect(STDOUT).to receive(:puts).with(output_headers)
            expect(STDOUT).to receive(:puts).with(account_output)
            transactions_processor.process
        end
    
        it 'does not process a chargeback if the transaction does not exist' do
            transactions = [
                { 'type' => 'deposit', 'client' => '1', 'tx' => '1','amount' => '5' },
                { 'type' => 'dispute', 'client' => '1', 'tx' => '1' },
                { 'type' => 'chargeback', 'client' => '1', 'tx' => '2' }
            ]
            generate_test_csv(transactions)

            account_output = '1, 0, 5, 5, false'
            expect(STDOUT).to receive(:puts).with(output_headers)
            expect(STDOUT).to receive(:puts).with(account_output)
            transactions_processor.process            
        end
    end
end

def generate_test_csv(array_of_hashes)
    CSV.open(test_file_path, "wb") do |csv|
        csv << array_of_hashes.first.keys
        array_of_hashes.each do |hash|
          csv << hash.values
        end
    end
end
