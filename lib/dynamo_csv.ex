defmodule DynamoCSV do
  @moduledoc """
  Entry point for the DynamoCSV tool.
  """

  alias ExAws.Dynamo

  defmodule Options do
    defstruct [:file, :dryrun, :table, :columns, :help]
  end

  @table_name "dev-passwords"

  def main(argv \\ []) do
    options = argv |> parse_args |> process_options
  end

  def process_options(%Options{help: true}) do
    IO.puts("REQUIRED: You must pass --file option")
    IO.puts("./dynamo_csv --file /path/to/file.csv")
    IO.puts("OPTIONAL: You can pass --dryrun option to ...")
    IO.puts("./dynamo_csv --dryrun --file /path/to/file.csv")
    IO.puts("OPTIONAL:You can pass --table name")
    IO.puts("./dynamo_csv --table my_table --file /path/to/file.csv")
    IO.puts("OPTIONAL:You can pass --columns")
    IO.puts("./dynamo_csv --table my_table --columns first_name,last_name --file /path/to/file.csv")
  end

  def process_options(options) do
    IO.puts("Parsing csv file... ")

    options
      |> record_list
      |> describe_items
      |> Enum.chunk_every(25)
      |> update_items(options.table, options.dryrun)
      |> Enum.filter(&remove_empty_returns/1)
      |> Enum.map(&gather_unprocessed/1)
      |> print_finished_stats

    IO.puts("Done!")
  end

  defp parse_args(argv) do
    {parsed, args, _} =
      argv
      |> OptionParser.parse(strict: [file: :string, dryrun: :boolean, table: :string, columns: :string, help: :boolean])

    %Options{
      file: Keyword.get(parsed, :file, :error),
      dryrun: Keyword.get(parsed, :dryrun, false),
      table: Keyword.get(parsed, :table, ""),
      help: Keyword.get(parsed, :help, false),
      columns: parsed |> Keyword.get(:columns, "") |> String.split(",")
    }
  end

  defp describe_items(record_list) do
    IO.puts("Found #{Enum.count(record_list)} items to insert")
    record_list
  end

  defp print_finished_stats(unprocessed_items) do
    IO.puts("#{Enum.count(unprocessed_items)} were unprocessed")
  end

  defp remove_empty_returns(%{"UnprocessedItems" => %{}}), do: false
  defp remove_empty_returns(%{"UnprocessedItems" => _}), do: true

  defp gather_unprocessed(%{"UnprocessedItems" => item}), do: item

  defp record_list(%Options{file: :error}), do: []

  defp record_list(options) do
    options.file
    |> File.stream!()
    |> CSV.decode(headers: true)
    |> map_to_put_requests(options.columns)
    |> Enum.to_list()
  end

  defp update_items(requests, table, true), do: Enum.map(requests, fn _ -> %{"UnprocessedItems" => %{}} end)
  defp update_items(requests, table, false), do: Enum.map(requests, fn (req) ->
    try do
      %{table => req}
      |> ExAws.Dynamo.batch_write_item()
      |> ExAws.request!()
    rescue
      e in ExAws.Error ->
        raise "Unable to communicate with AWS, check your network settings and credentials"
    end
  end)

  defp map_to_put_requests(data, columns) do
    Stream.map(data, fn {:ok, res} ->
      record =
        columns
        |> Enum.reduce(%{}, fn x, acc ->
          Map.put_new(acc, x, Map.get(res, x))
        end)
      [put_request: [item: record]]
    end)
  end

end
