defmodule Glific.BigqueryTest do
  use Glific.DataCase
  use Oban.Testing, repo: Glific.Repo
  use ExUnit.Case

  alias Glific.{
    Bigquery,
    Fixtures,
    Jobs.BigQueryWorker,
    Messages,
    Messages.Message,
    Seeds.SeedsDev
  }

  setup do
    organization = SeedsDev.seed_organizations()
    SeedsDev.seed_contacts(organization)
    SeedsDev.seed_messages()
    SeedsDev.seed_flows()
    :ok
  end

  @max_id 100
  @min_id 0

  test "queue_table_data/4 should create job for messages", attrs do
    data =
      Message
      |> select([m], m.id)
      |> where([m], m.organization_id == ^attrs.organization_id)
      |> order_by([m], asc: m.id)
      |> Repo.all()

    max_id = if is_list(data), do: List.last(data), else: @max_id

    BigQueryWorker.queue_table_data("messages", attrs.organization_id, @min_id, max_id)
    assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :bigquery)
  end

  test "queue_table_data/4 should create job for messages_delta", attrs do
    message = Fixtures.message_fixture(Map.merge(attrs, %{flow: :inbound}))
    Messages.update_message(message, %{body: "hello"})

    data =
      Message
      |> select([m], m.id)
      |> where([m], m.organization_id == ^attrs.organization_id)
      |> order_by([m], asc: m.id)
      |> Repo.all()

    max_id = if is_list(data), do: List.last(data), else: @max_id
    BigQueryWorker.queue_table_data("messages_delta", attrs.organization_id, @min_id, max_id)
    assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :bigquery)
  end

  test "queue_table_data/4 should create job for contacts", attrs do
    BigQueryWorker.queue_table_data("contacts", attrs.organization_id, @min_id, @max_id)
    assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :bigquery)
  end

  test "queue_table_data/4 should create job for flows", attrs do
    BigQueryWorker.queue_table_data("flows", attrs.organization_id, @min_id, @max_id)
    assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :bigquery)
  end

  @unix_time 1_464_096_368
  @formated_time "2016-05-24 18:56:08"
  test "format_date/2 should create job for contacts", attrs do
    {:ok, datetime} = DateTime.from_unix(@unix_time)
    assert nil == Bigquery.format_date(nil, attrs.organization_id)
    assert @formated_time == Bigquery.format_date(datetime, attrs.organization_id)

    assert @formated_time ==
             Bigquery.format_date(DateTime.to_string(datetime), attrs.organization_id)
  end
end
