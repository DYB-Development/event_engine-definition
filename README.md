# EventEngine::Definition

The plain-Ruby event-definition contract for the [EventEngine](https://github.com/DYB-Development/event_engine) pipeline.

EventEngine is a schema-first event pipeline: domain events are **declared** with a Ruby DSL, **compiled** into a canonical schema, and **emitted** through generated helper methods that hand each event to a publisher. This gem holds the plain-Ruby foundation of that pipeline — the `EventEngine::EventDefinition` DSL, the shared schema value objects, and the build step that turns a set of definitions into a committed helper file — with **no Rails dependency**.

Lightweight domain-pack gems depend on this contract; the full dispatch, registry, and Rails-engine machinery lives in [`event_engine`](https://github.com/DYB-Development/event_engine) and is wired in at runtime.

## Installation

Requires Ruby `>= 3.2.0`.

Add the gem to your Gemfile:

```ruby
gem "event_engine-definition"
```

Then run `bundle install`, and require it:

```ruby
require "event_engine/definition"
```

## A worked example

### The data you want to capture

Say a lead just signed up in your Rails app. You have the record in hand:

```ruby
lead = Lead.create!(
  email:   "ada@example.com",
  name:    "Ada Lovelace",
  company: "Analytical Engines",
  source:  "webinar"
)
# => #<Lead id: 42, email: "ada@example.com", name: "Ada Lovelace",
#           company: "Analytical Engines", source: "webinar", created_at: …>
```

You want to announce that a lead was created so the rest of the system — analytics, CRM sync, a welcome email — can react. Done ad hoc, every place that raises this "event" builds its own hash: one sends `{ email: … }`, another `{ email_address: …, lead: 42 }`, a third forgets `source`. The keys drift, fields go missing, and every consumer has to defend against all of it.

Defining the event fixes the shape **once**, so every producer emits the same data in the same format and every consumer can rely on it — with the names checked and the shape fingerprinted so it can't change silently.

### Declare the event

```ruby
class LeadCreated < EventEngine::EventDefinition
  event_name :lead_created   # the event's identity
  event_type :domain         # how you classify it
  domain     :marketing      # the bounded context it belongs to

  input :lead                # the object the event is built from

  required_payload :lead_id, from: :lead, attr: :id
  required_payload :email,   from: :lead, attr: :email
  required_payload :name,    from: :lead, attr: :name
  optional_payload :company, from: :lead, attr: :company
  optional_payload :source,  from: :lead, attr: :source
end
```

Read each payload line as: *"the event carries `lead_id`, and its value comes from `lead.id`."* The `input :lead` names the object you hand in; each `from:` points back at that input, and each `attr:` is the attribute read off it.

### Generate the pack (a build step)

Generating a pack compiles your definitions (validating names, reserved fields, and subjects) and writes two files you commit:

- a `MarketingEvents` module with one typed method per event, and
- a `schema.json` alongside it — the committed contract downstream consumers read.

This is a build-time step; your app never runs it while serving requests.

> **TODO — no generate task exists yet.** There is currently **no rake task** for this. The helper and `schema.json` are produced only by calling `EventEngine::DomainPackBuild.run` directly (as the test suite does). The pack-facing task that wraps it — the analogue of `event_engine`'s `event_engine:schema:dump` — still needs to be ported into this gem.

### Emit the event (at runtime)

With the helper generated, producing the event anywhere in your app is one call. You hand it the whole `lead`; the contract decides what is captured off it:

```ruby
MarketingEvents.lead_created(lead: lead)
```

Every `lead_created` event, from anywhere in the app, carries exactly the shape you declared:

```ruby
{
  lead_id: 42,
  email:   "ada@example.com",
  name:    "Ada Lovelace",
  company: "Analytical Engines",
  source:  "webinar"
}
```

> **Where the work happens:** this gem *records* the `from:`/`attr:` mapping and forwards the raw `lead` under `inputs:`. Reading `lead.id`, `lead.email`, … to build that payload is done by the publisher the `event_engine` runtime supplies — see [How it fits](#how-it-fits-with-event_engine). Until one is configured the default publisher raises, so wire it once at boot:
>
> ```ruby
> EventEngine::Definition.publisher = my_publisher   # any object with #publish(event_name, **envelope)
> ```

### More examples

See **[docs/examples.md](docs/examples.md)** for an event built from **multiple inputs** (an order and its customer) and a **lifecycle** that generates one event per step (started / completed / failed).

## The DSL reference

### Declarations, field by field

| Declaration | Required to be valid? | What it does |
|---|---|---|
| `event_name :x` | **Yes** — `schema` raises without it | The event's unique, snake_case identity. |
| `event_type :x` | **Yes** — `schema` raises without it | A classification symbol you choose (e.g. `:domain`, `:product`). Not enumerated by this gem. |
| `domain :x` | No | The bounded context the event belongs to. Keys the event in the registry and scopes the generated helpers. |
| `subject :x` | No | The aggregate the event is about. If set, it must be registered in a `SubjectRegistry` when the definitions are compiled. |
| `input :x` | — | Declares an **input** the event is built from. |
| `optional_input :x` | — | Same, but the input may be omitted at the call site. |
| `required_payload :name, from:, attr:` | — | Declares a **payload field** in the emitted event. |
| `optional_payload :name, from:, attr:` | — | Same, but the field is not a guaranteed part of the payload. |

### Inputs vs. payload

These are two different layers:

- **Inputs are the arguments you hand the event** — the whole objects your code already has. Each becomes a keyword argument on the generated helper.
  - `input :lead` → `lead:` is **required** at the call site.
  - `optional_input :campaign` → `campaign:` **defaults to `nil`** and may be omitted.

- **Payload fields are the flat data the event carries**, described as a mapping *off* those inputs (`from:` = which input, `attr:` = which attribute on it).
  - `required_payload` → the field is a **guaranteed** part of the payload.
  - `optional_payload` → the field may be absent.
  - The `required` flag is stored in the schema and is part of the event's **fingerprint**, so changing it changes the contract.

### Reserved names

Compilation rejects definitions that use names owned by the event envelope:

- **Payload field names** may not be any of:
  `event_name`, `event_type`, `event_version`, `occurred_at`, `created_at`, `updated_at`, `published_at`, `metadata`, `idempotency_key`, `attempts`, `dead_lettered_at`, `aggregate_type`, `aggregate_id`, `aggregate_version`.
- **Input names** may not collide with the envelope keys:
  `event_version`, `occurred_at`, `metadata`, `idempotency_key`, `aggregate_type`, `aggregate_id`, `aggregate_version`.

A payload field must also have a `from:` that references a declared input, and each event name must be snake_case.

### Inspecting the compiled schema

Every definition compiles to a `Schema` value object:

```ruby
schema = LeadCreated.schema

schema.event_name       # => :lead_created
schema.required_inputs  # => [:lead]
schema.fingerprint      # => "…sha256 of the event's structure…"
schema.to_h             # => plain data hash (JSON-safe)
schema.to_ruby          # => a Ruby source string that rebuilds the Schema
```

The fingerprint is a stable hash of the event's **structure** (name, type, inputs, payload fields) — incidental fields like `domain` don't change it, so a matching fingerprint means a matching contract.

## How it fits with `event_engine`

This gem defines and generates; `event_engine` runs. The seam between them is the **publisher port** (`EventEngine::Definition.publisher`):

```
this gem                                    event_engine (host runtime)
────────────────────────────────           ──────────────────────────────
EventDefinition DSL                          registers as the publisher
        │ compile                            ────────────────────►
        ▼                                    reads the raw inputs via the
generated helper  ──publish(event)──►        schema's from:/attr: mapping,
+ committed schema.json                       then dispatches, persists, brokers…
```

A domain pack depends only on `event_engine-definition` to declare its events and build its helper file. In an app that also has `event_engine` installed, `event_engine` provides a real publisher adapter and assigns it to `EventEngine::Definition.publisher`, so calling a generated helper hands the event to the full runtime. Nothing in this gem knows how events are dispatched — that decision lives entirely in `event_engine`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then:

- `rake test` — run the test suite
- `bin/console` — an interactive prompt with the gem loaded

## License

Available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
