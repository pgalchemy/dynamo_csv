defmodule DynamoCSV do
  @moduledoc """
  Entry point for the DynamoCSV tool.
  """

  alias ExAws.Dynamo

  defmodule Options do
    defstruct [:file, :dryrun, :table, :columns]
  end

  @table_name "dev-passwords"

  def main(argv \\ []) do
    IO.puts("Parsing csv file... ")
    opts = argv |> parse_args

    results =
      opts
      |> record_list
      |> describe_items
      |> Enum.chunk_every(25)
      |> update_items(opts.table, opts.dryrun)
      |> Enum.filter(&remove_empty_returns/1)
      |> Enum.map(&gather_unprocessed/1)
      |> print_finished_stats

    IO.puts("Done!")
  end

  defp parse_args(argv) do
    {parsed, args, _} =
      argv
      |> OptionParser.parse(strict: [file: :string, dryrun: :boolean, table: :string, columns: :string])

    columns =
      parsed
      |> Keyword.get(:columns, "")
      |> String.split(",")

    %Options{
      file: Keyword.get(parsed, :file, :error),
      dryrun: Keyword.get(parsed, :dryrun, false),
      table: Keyword.get(parsed, :table, ""),
      columns: columns
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
        @columns
        |> Enum.reduce(%{}, fn x, acc ->
          Map.put_new(acc, x, Map.get(res, x))
        end)
      [put_request: [item: record]]
    end)
  end

end
