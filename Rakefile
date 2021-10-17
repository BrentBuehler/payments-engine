require_relative "config/application"

Rails.application.load_tasks

desc "Process a CSV file of transactions"
task :process_transactions, [:file_path]  => :environment  do |t, args|
    TransactionsProcessor.new(args[:file_path]).process
end

desc "Clear the database"
task :clear_database  => :environment  do |t|
  Transaction.destroy_all
  Account.destroy_all
end
