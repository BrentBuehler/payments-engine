# payments-engine
A simple payments engine that reads in a series of transactions from a CSV, performs the transaction, and outputs the account balances

1) [Install Docker](https://docs.docker.com/get-docker/) if not already installed
2) Launch Docker
3) From the payments-engine project root, run `docker-compose up`
4) Once built, open another tab and run `docker ps` to list the running containers. Find and copy the container id for the "payments-engine_web" image, then run `docker exec -it <ContainerID> sh` to open a shell within the app container (ex: `docker exec -it b4914d37fd25 sh`.
5) Run `rake db:create && rake db:migrate`. This will create the Postgres database and run the migration file that's in db/migrate.
6) Place a csv file containing the transactions somewhere in the payments-engine directory. To process the csv of transactions, run `rake 'process_transactions[path/to/myfile.csv]'`, inserting the path from the project root to where the csv file is located (ex: `rake 'process_transactions[csv/sample_transactions.csv]'`). The transactions should then process and the account balances printed to stdout.

If you'd like to run the specs in spec/transactions_processor_spec.rb, run `rake db:migrate RAILS_ENV=test` then `rspec` within the container.
