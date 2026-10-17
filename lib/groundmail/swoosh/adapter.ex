defmodule Groundmail.Swoosh.Adapter do
  @moduledoc """
  Swoosh adapter for the [Groundmail](https://groundmail.dev) transactional email API.

  ## Configuration

      # config/runtime.exs
      config :my_app, MyApp.Mailer,
        adapter: Groundmail.Swoosh.Adapter,
        api_key: System.fetch_env!("GROUNDMAIL_API_KEY")

  Swoosh makes the HTTP request through its configured API client
  (`config :swoosh, :api_client, Swoosh.ApiClient.Req`, or Finch/Hackney).

  ## Provider options

      new()
      |> put_provider_option(:tags, %{"flow" => "signup"})
      |> put_provider_option(:idempotency_key, "welcome-42")
      |> put_provider_option(:scheduled_at, "2026-11-01T09:00:00Z")
      |> put_provider_option(:template, %{id: "welcome", variables: %{"name" => "Ada"}})

  `:template` sends a Groundmail template instead of `html_body`/`text_body`.
  """

  use Swoosh.Adapter, required_config: [:api_key]

  alias Swoosh.Email
  import Swoosh.Email.Render, only: [render_recipient: 1]

  @base_url "https://api.groundmail.dev"

  @impl true
  def deliver(%Email{} = email, config \\ []) do
    headers =
      [
        {"Content-Type", "application/json"},
        {"Accept", "application/json"},
        {"Authorization", "Bearer #{config[:api_key]}"},
        {"User-Agent", "swoosh_groundmail/#{Application.spec(:swoosh_groundmail, :vsn)}"}
      ] ++ idempotency_header(email)

    body = email |> prepare_body() |> Swoosh.json_library().encode!()
    url = [base_url(config), "/emails"]

    case Swoosh.ApiClient.post(url, headers, body, email) do
      {:ok, status, _headers, response} when status in 200..299 ->
        decoded = decode(response)
        {:ok, %{id: decoded["id"], status: decoded["status"]}}

      {:ok, status, _headers, response} ->
        {:error, {status, decode(response)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  def prepare_body(%Email{} = email) do
    %{}
    |> put_value("from", render_recipient(email.from))
    |> put_value("to", Enum.map(email.to, &render_recipient/1))
    |> put_list("cc", email.cc)
    |> put_list("bcc", email.bcc)
    |> put_value("reply_to", email.reply_to && render_recipient(email.reply_to))
    |> put_value("subject", email.subject)
    |> put_value("html", email.html_body)
    |> put_value("text", email.text_body)
    |> put_headers(email.headers)
    |> put_attachments(email.attachments)
    |> put_provider_options(email.provider_options)
  end

  defp base_url(config), do: String.trim_trailing(config[:base_url] || @base_url, "/")

  defp idempotency_header(%Email{provider_options: %{idempotency_key: key}}) when is_binary(key),
    do: [{"Idempotency-Key", key}]

  defp idempotency_header(_email), do: []

  defp put_value(body, _key, nil), do: body
  defp put_value(body, _key, ""), do: body
  defp put_value(body, key, value), do: Map.put(body, key, value)

  defp put_list(body, _key, []), do: body
  defp put_list(body, key, recipients), do: Map.put(body, key, Enum.map(recipients, &render_recipient/1))

  defp put_headers(body, headers) when map_size(headers) == 0, do: body
  defp put_headers(body, headers), do: Map.put(body, "headers", headers)

  defp put_attachments(body, []), do: body

  # Swoosh prepends attachments; reverse to keep the order they were added.
  defp put_attachments(body, attachments) do
    Map.put(body, "attachments", attachments |> Enum.reverse() |> Enum.map(&attachment/1))
  end

  defp attachment(%Swoosh.Attachment{} = attachment) do
    base = %{
      "name" => attachment.filename,
      "content_type" => attachment.content_type,
      "data" => Swoosh.Attachment.get_content(attachment, :base64)
    }

    case attachment.type do
      :inline -> Map.put(base, "content_id", attachment.cid || attachment.filename)
      _ -> base
    end
  end

  defp put_provider_options(body, options) do
    Enum.reduce(options, body, fn
      {:tags, tags}, acc when is_map(tags) or is_list(tags) -> Map.put(acc, "tags", tags)
      {:scheduled_at, %DateTime{} = at}, acc -> Map.put(acc, "scheduled_at", DateTime.to_iso8601(at))
      {:scheduled_at, at}, acc when is_binary(at) -> Map.put(acc, "scheduled_at", at)
      {:template, %{} = template}, acc -> Map.put(acc, "template", template)
      {:unsubscribe, value}, acc when is_boolean(value) -> Map.put(acc, "unsubscribe", value)
      _other, acc -> acc
    end)
  end

  defp decode(""), do: %{}

  defp decode(body) when is_binary(body) do
    case Swoosh.json_library().decode(body) do
      {:ok, decoded} -> decoded
      {:error, _} -> %{"error" => body}
    end
  end

  defp decode(body), do: body
end
