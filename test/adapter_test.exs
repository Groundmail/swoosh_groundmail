defmodule Groundmail.Swoosh.AdapterTest do
  use ExUnit.Case, async: true

  import Swoosh.Email
  alias Groundmail.Swoosh.Adapter

  setup do
    bypass = Bypass.open()
    config = [api_key: "gm_test_key", base_url: "http://localhost:#{bypass.port}"]
    {:ok, bypass: bypass, config: config}
  end

  defp email do
    new()
    |> from({"Acme", "noreply@acme.test"})
    |> to("user@example.com")
    |> cc({"Ops", "ops@acme.test"})
    |> reply_to("support@acme.test")
    |> subject("Reset your password")
    |> html_body("<p>Reset</p>")
    |> text_body("Reset")
  end

  test "delivers through the Groundmail API", %{bypass: bypass, config: config} do
    Bypass.expect_once(bypass, "POST", "/emails", fn conn ->
      {:ok, raw, conn} = Plug.Conn.read_body(conn)
      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer gm_test_key"]
      assert Plug.Conn.get_req_header(conn, "idempotency-key") == ["reset-42"]

      assert Jason.decode!(raw) == %{
               "from" => ~s("Acme" <noreply@acme.test>),
               "to" => ["user@example.com"],
               "cc" => [~s("Ops" <ops@acme.test>)],
               "reply_to" => "support@acme.test",
               "subject" => "Reset your password",
               "html" => "<p>Reset</p>",
               "text" => "Reset",
               "headers" => %{"X-Entity-Ref-ID" => "42"},
               "tags" => %{"flow" => "reset"}
             }

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, ~s({"id":"em_123","status":"queued"}))
    end)

    message =
      email()
      |> header("X-Entity-Ref-ID", "42")
      |> put_provider_option(:tags, %{"flow" => "reset"})
      |> put_provider_option(:idempotency_key, "reset-42")

    assert Adapter.deliver(message, config) == {:ok, %{id: "em_123", status: "queued"}}
  end

  test "sends attachments and inline images" do
    message =
      email()
      |> attachment(Swoosh.Attachment.new({:data, "hello"}, filename: "notes.txt", content_type: "text/plain"))
      |> attachment(
        Swoosh.Attachment.new({:data, "png"},
          filename: "logo.png",
          content_type: "image/png",
          type: :inline,
          cid: "logo"
        )
      )

    assert Adapter.prepare_body(message)["attachments"] == [
             %{"name" => "notes.txt", "content_type" => "text/plain", "data" => Base.encode64("hello")},
             %{
               "name" => "logo.png",
               "content_type" => "image/png",
               "data" => Base.encode64("png"),
               "content_id" => "logo"
             }
           ]
  end

  test "sends a template with variables" do
    body =
      new()
      |> from("noreply@acme.test")
      |> to("user@example.com")
      |> put_provider_option(:template, %{id: "welcome", variables: %{"name" => "Ada"}})
      |> put_provider_option(:scheduled_at, ~U[2026-11-01 09:00:00Z])
      |> Adapter.prepare_body()

    assert body["template"] == %{id: "welcome", variables: %{"name" => "Ada"}}
    assert body["scheduled_at"] == "2026-11-01T09:00:00Z"
    refute Map.has_key?(body, "html")
  end

  test "returns API errors", %{bypass: bypass, config: config} do
    Bypass.expect_once(bypass, "POST", "/emails", fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(422, ~s({"error":"Domain not verified"}))
    end)

    assert Adapter.deliver(email(), config) == {:error, {422, %{"error" => "Domain not verified"}}}
  end

  test "requires an api_key" do
    assert_raise ArgumentError, ~r/api_key/, fn -> Adapter.validate_config([]) end
  end
end
