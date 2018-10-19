defmodule DynamoCSV.Help do
  @moduledoc """
  Prints possible required and optional arguments with examples.

  DynamoCSV.Help.output
  """

  def output do
    IO.puts("""
    -------------------------------------
    REQUIRED: You must pass --file option

    ./dynamo_csv --file /path/to/file.csv
    -------------------------------------

    -------------------------------------
    OPTIONAL: You can pass --dryrun option.
    It will not submit data to Amazon.
    The output shows how many records would be processed

    /dynamo_csv --dryrun --file /path/to/file.csv
    -------------------------------------

    -------------------------------------
    OPTIONAL: You can pass --table option to specify table name

    ./dynamo_csv --table my_table --file /path/to/file.csv
    -------------------------------------

    -------------------------------------
    OPTIONAL: You can pass --columns to specify columns

    ./dynamo_csv --table my_table --columns first_name,last_name --file /path/to/file.csv
    -------------------------------------
    """)
  end
end
