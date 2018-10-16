# DynamoCSV

There are [some options](https://docs.aws.amazon.com/datapipeline/latest/DeveloperGuide/dp-importexport-ddb.html) for uploading data from a CSV file into Dynamo, but they seem to be overly complicated. This is a small program that you'll need to provide a table name, column names and csv file and it will insert the data for you quickly using Amazons Bulk insert, so it's quick.

## Installation
You'll need Erlang installed. The easiest way I've found is to use [asdf](https://github.com/asdf-vm/asdf). Once you have `asdf` setup, run:
```
asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf install erlang 21.1
asdf global erlang 21.1
```

Now you can grab the lastest distribution of `dynamo_csv` from the release page and put it in your path.

## Usage

Assuming you have it in your path, just run `dynamo_csv --file path/to/file.csv`
