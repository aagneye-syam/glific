defmodule TestProducerFlow do
  use GenStage

  alias Glific.{
    Fixtures,
    Repo,
  }

  @checks %{
    0 => "help",
    1 => "language",
    2 => "newcontact",
  }
  @num_checks length(Map.keys(@checks))

  @doc false
  @spec get_checks() :: %{integer => {}}
  def get_checks, do: @checks

  def start_link(demand) do
    GenStage.start_link(__MODULE__, demand, name: TestProducerFlow)
  end

  def init(demand), do: {:producer, demand}

  def handle_demand(demand, counter) when counter > @num_checks + 1 do
    send(:test, {:called_back})
    {:stop, :normal, demand}
  end

  def handle_demand(demand, counter) when demand > 0 do
    events =
      Enum.map(
        counter..(counter + demand - 1),
        fn c -> Fixtures.message_fixture(%{body: @checks[rem(c, @num_checks + 1)]}) end
      )

    {:noreply, events, demand + counter}
  end
end

defmodule Glific.Processor.ConsumerFlowTest do
  use Glific.DataCase

  alias Glific.{
    Messages.Message,
    Processor.ConsumerFlow,
    Repo,
    Seeds.SeedsDev,
  }

  setup do
    default_provider = SeedsDev.seed_providers()
    SeedsDev.seed_organizations(default_provider)
    SeedsDev.seed_contacts()
    SeedsDev.seed_messages()
    :ok
  end

  test "should behave like consumer" do
    # keep track of current messages
    message_count = Repo.aggregate(Message, :count)

    {:ok, producer} = TestProducerFlow.start_link(1)
    {:ok, _consumer} = ConsumerFlow.start_link(
      producer: producer,
      name: TestConsumerFlow,
      wakeup_timeout: 1
    )

    Process.register(self(), :test)
    assert_receive({:called_back}, 10_000)

    new_message_count = Repo.aggregate(Message, :count)
    assert new_message_count > message_count
end
end
