defmodule NewRelicTesla.Telemetry.Tesla do
  @moduledoc """
  Provides `Tesla` instrumentation via `telemetry`.

  Tesla pipelines are auto-discovered and instrumented.

  We automatically gather:

  * Transaction metrics and events
  * Transaction spans
  """
  use GenServer

  alias NewRelic.Transaction.Reporter

  @doc false
  def start_link(_) do
    config = %{
      handler_id: {:new_relic, :tesla}
    }

    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @tesla_stop [:tesla, :request, :stop]
  @tesla_exception [:tesla, :request, :exception]

  @tesla_events [
    @tesla_stop,
    @tesla_exception
  ]

  @doc false
  @impl GenServer
  def init(config) do
    :telemetry.attach_many(
      config.handler_id,
      @tesla_events,
      &__MODULE__.handle_event/4,
      config
    )

    Process.flag(:trap_exit, true)
    {:ok, config}
  end

  @doc false
  @impl GenServer
  def terminate(_reason, %{handler_id: handler_id}) do
    :telemetry.detach(handler_id)
  end

  def handle_event(
        _event,
        %{duration: duration_ns} = _measurements,
        metadata,
        _config
      ) do
    end_time = System.system_time(:microsecond) / 1000

    duration_ms = to_ms(duration_ns)
    duration_s = duration_ms / 1000
    start_time = end_time - duration_ms

    pid = inspect(self())
    id = {:tesla_request, make_ref()}
    parent_id = Process.get(:nr_current_span) || :root

    span_attrs = build_attrs(metadata)

    %{
      "http.method" => method,
      "http.target" => target,
      "http.host" => host
    } = span_attrs

    metric_name = "Tesla/#{method} #{host}#{target}"

    Reporter.add_trace_segment(%{
      primary_name: metric_name,
      secondary_name: metric_name,
      attributes: span_attrs,
      id: id,
      pid: pid,
      parent_id: parent_id,
      start_time: start_time,
      end_time: end_time
    })

    NewRelic.report_span(
      timestamp_ms: start_time,
      duration_s: duration_s,
      name: metric_name,
      edge: [span: id, parent: parent_id],
      category: "external",
      attributes:
        %{
          component: "Tesla",
          "span.kind": :client
        }
        |> Map.merge(span_attrs)
    )

    metric_identifier = {:external, "#{host}#{target}", "Tesla", method}
    NewRelic.report_metric(metric_identifier, duration_s: duration_s)
    Reporter.track_metric({metric_identifier, duration_s: duration_s})

    NewRelic.incr_attributes(
      externalCallCount: 1,
      externalDuration: duration_s,
      external_call_count: 1,
      external_duration_ms: duration_ms,
      "external.#{host}.call_count": 1,
      "external.#{host}.duration_ms": duration_ms
    )
  end

  def handle_event(_event, _value, _metadata, _config) do
    :ignore
  end

  defp to_ms(nil), do: nil
  defp to_ms(ns), do: System.convert_time_unit(ns, :nanosecond, :microsecond) / 1000

  defp build_attrs(%{
         env: %Tesla.Env{
           method: method,
           url: url,
           status: status_code,
           headers: headers,
           query: query
         }
       }) do
    url = Tesla.build_url(url, query)
    uri = URI.parse(url)

    attrs = %{
      "http.method" => http_method(method),
      "http.url" => url,
      "http.target" => uri.path,
      "http.host" => uri.host,
      "http.scheme" => uri.scheme,
      "http.status_code" => status_code
    }

    maybe_append_content_length(attrs, headers)
  end

  defp maybe_append_content_length(attrs, headers) do
    case Enum.find(headers, fn {k, _v} -> k == "content-length" end) do
      nil ->
        attrs

      {_key, content_length} ->
        Map.put(attrs, :"http.response_content_length", content_length)
    end
  end

  defp http_method(method) do
    method
    |> Atom.to_string()
    |> String.upcase()
  end
end
