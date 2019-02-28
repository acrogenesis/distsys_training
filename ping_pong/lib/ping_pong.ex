defmodule PingPong do
  require Logger

  defmodule Producer do
    def start(caller) do
      producer = spawn(fn -> init(caller) end)
      Process.register(producer, :producer)
      producer
    end

    def stop do
      send(:producer, :stop)
    end

    def produce(producer) do
      send(producer, {:produce, self()})

      receive do
        :finished ->
          :ok
      end
    end

    def crash do
      send(:producer, :crash)
    end

    def init(caller) do
      receive do
        {:hello, consumer} ->
          send(caller, {:starting, self()})
          producer(consumer, 0)

        :stop ->
          :ok
      end
    end

    def producer(consumer, n) do
      receive do
        {:produce, pid} ->
          Logger.info("Producing: #{n}")
          send(consumer, {:ping, n})
          send(pid, :finished)
          producer(consumer, n + 1)

        :stop ->
          send(consumer, :bye)

        :crash ->
          42 / 0
      end
    end
  end

  defmodule Consumer do
    def start(producer) do
      consumer = spawn(fn -> init(producer) end)
      Process.register(consumer, :consumer)
      consumer
    end

    def stop, do: send(:consumer, :stop)

    def init(producer) do
      send(producer, {:hello, self()})
      consume(0)
    end

    def consume(expected) do
      next_num =
        receive do
          {:ping, ^expected} ->
            Logger.info("Received expected value: #{expected}")
            expected + 1

          {:ping, unexpected} ->
            Logger.info("Received unexpected value: #{unexpected}")
            unexpected + 1

          {:expected_value, pid} ->
            send(pid, {:value, expected})
            consume(expected)
        end

      consume(next_num)
    end
  end
end
