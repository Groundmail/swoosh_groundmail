<p align="center">
  <a href="https://groundmail.dev">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://app.groundmail.dev/images/github/readme-logo-dark.png">
      <img alt="Groundmail" src="https://app.groundmail.dev/images/github/readme-logo-light.png" height="44">
    </picture>
  </a>
</p>

<h1 align="center">Groundmail for Swoosh</h1>

<p align="center">
  A <a href="https://hexdocs.pm/swoosh">Swoosh</a> adapter for the Groundmail transactional email API.<br>
  Send Phoenix and Elixir email through Groundmail with your existing mailer.
</p>

<p align="center">
  <a href="https://hex.pm/packages/swoosh_groundmail"><img alt="Hex" src="https://img.shields.io/hexpm/v/swoosh_groundmail?color=a3461f&label=hex"></a>
  <a href="./LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-b48f62"></a>
</p>

<p align="center">
  <a href="https://docs.groundmail.dev/frameworks/phoenix">Docs</a> ·
  <a href="https://app.groundmail.dev/signup">Get a free account</a> ·
  <a href="https://groundmail.dev">groundmail.dev</a>
</p>

---

## Install

```elixir
# mix.exs
def deps do
  [
    {:swoosh_groundmail, "~> 0.1"},
    {:req, "~> 0.5"}
  ]
end
```

## Configure

```elixir
# config/runtime.exs
config :my_app, MyApp.Mailer,
  adapter: Groundmail.Swoosh.Adapter,
  api_key: System.fetch_env!("GROUNDMAIL_API_KEY")

# config/config.exs (Phoenix apps already set an API client)
config :swoosh, :api_client, Swoosh.ApiClient.Req
```

## Send

```elixir
import Swoosh.Email

new()
|> from({"Acme", "noreply@yourdomain.com"})
|> to(user.email)
|> subject("Confirm your account")
|> html_body("<p>Click the link to confirm.</p>")
|> text_body("Click the link to confirm.")
|> MyApp.Mailer.deliver()
#=> {:ok, %{id: "em_…", status: "queued"}}
```

The From address must be on a domain you have verified in Groundmail. Attachments and inline images (`attachment/2` with `type: :inline`) are sent with the message.

## Provider options

```elixir
new()
|> put_provider_option(:tags, %{"flow" => "signup"})
|> put_provider_option(:idempotency_key, "welcome-#{user.id}")
|> put_provider_option(:scheduled_at, ~U[2026-11-01 09:00:00Z])
|> put_provider_option(:template, %{id: "welcome", variables: %{"name" => user.name}})
```

| Option | Purpose |
|--------|---------|
| `:tags` | Map of tags for filtering and webhooks |
| `:idempotency_key` | Send once, even when your code retries |
| `:scheduled_at` | `DateTime` or ISO 8601 string to send later |
| `:template` | Send a Groundmail template (`id` or alias, plus `variables`) instead of a body |

## Contributing

Found a bug or want something added? [Open an issue](https://github.com/Groundmail/swoosh_groundmail/issues). This code is published here on each release, so we port fixes rather than merging pull requests directly.

## Why Groundmail

- **Our own mail servers and IP space.** Your password resets and receipts don't share a pool with bulk marketing senders.
- **Transactional email only.** No newsletters or cold outreach on the platform, which keeps the sending reputation clean.
- **Start free.** 3,000 emails a month on the Free plan; Pro is 50,000 emails for $20/month. Dedicated IPs on Scale.
- **Built for code and for agents.** REST API, SMTP, SDKs for Node, Python, Go, PHP and Ruby, a CLI, and an MCP server for Claude, ChatGPT and Cursor.

## All Groundmail libraries

| Use | Package |
|-----|---------|
| Node.js / TypeScript | [`groundmail`](https://www.npmjs.com/package/groundmail) on npm |
| Python (Django), Go, Ruby (Rails Action Mailer) | [Groundmail/groundmail-sdks](https://github.com/Groundmail/groundmail-sdks) |
| PHP | [Groundmail/groundmail-php](https://github.com/Groundmail/groundmail-php) |
| Laravel | [Groundmail/groundmail-laravel](https://github.com/Groundmail/groundmail-laravel) |
| Symfony Mailer | [Groundmail/groundmail-symfony-mailer](https://github.com/Groundmail/groundmail-symfony-mailer) |
| Nodemailer | [Groundmail/groundmail-nodemailer](https://github.com/Groundmail/groundmail-nodemailer) |
| NestJS | [Groundmail/nestjs-groundmail](https://github.com/Groundmail/nestjs-groundmail) |
| Strapi | [Groundmail/strapi-provider-email-groundmail](https://github.com/Groundmail/strapi-provider-email-groundmail) |
| Medusa | [Groundmail/medusa-notification-groundmail](https://github.com/Groundmail/medusa-notification-groundmail) |
| AdonisJS | [Groundmail/adonisjs-groundmail](https://github.com/Groundmail/adonisjs-groundmail) |
| Phoenix (Swoosh) | [Groundmail/swoosh_groundmail](https://github.com/Groundmail/swoosh_groundmail) |
| CLI | [`groundmail-cli`](https://www.npmjs.com/package/groundmail-cli) on npm |
| MCP server (Claude, ChatGPT, Cursor) | [Groundmail/groundmail-mcp](https://github.com/Groundmail/groundmail-mcp) |
| Agent skills and Claude Code plugin | [Groundmail/groundmail-skills](https://github.com/Groundmail/groundmail-skills) |
| Email templates (React Email, MJML, HTML) | [Groundmail/email-templates](https://github.com/Groundmail/email-templates) |

[Website](https://groundmail.dev) · [Docs](https://docs.groundmail.dev) · [Pricing](https://groundmail.dev/pricing) · [Sign up free](https://app.groundmail.dev/signup)
