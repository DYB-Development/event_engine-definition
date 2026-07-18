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

## Usage

### 1. Declare an event

Subclass `EventEngine::EventDefinition` and describe the event with the DSL:

```ruby
require "event_engine/definition"

class LeadCreated < EventEngine::EventDefinition
  event_name :lead_created   # required — snake_case identity
  event_type :domain         # required — classification symbol
  domain     :marketing      # optional — bounded context

  input          :lead       # a required input
  optional_input :campaign   # an optional input

  required_payload :email,  from: :lead,     attr: :email
  optional_payload :source, from: :campaign, attr: :source
end
```

### The DSL, field by field

| Declaration | Required to be valid? | What it does |
|---|---|---|
| `event_name :x` | **Yes** — `schema` raises without it | The event's unique, snake_case identity. |
| `event_type :x` | **Yes** — `schema` raises without it | A classification symbol you choose (e.g. `:domain`, `:product`). Not enumerated by this gem. |
| `domain :x` | No | The bounded context the event belongs to. Keys the event in the registry and scopes the generated helpers. |
| `subject :x` | No | The aggregate the event is about. If set, it must be registered in a `SubjectRegistry` when the definitions are compiled. |
| `input :x` | — | Declares an **input** the event is built from. See inputs vs. payload below. |
| `optional_input :x` | — | Same, but the input may be omitted at the call site. |
| `required_payload :name, from:, attr:` | — | Declares a **payload field** in the emitted event. See inputs vs. payload below. |
| `optional_payload :name, from:, attr:` | — | Same, but the field is not a guaranteed part of the payload. |

### Inputs vs. payload

These are two different layers, and this is the part worth getting right:

- **Inputs are the arguments you hand the event.** Each `input`/`optional_input` becomes a keyword argument on the generated helper method — the whole objects your code already has (a record, a struct, a hash-like value).
  - `input :lead` → `lead:` is **required** at the call site.
  - `optional_input :campaign` → `campaign:` **defaults to `nil`** and may be omitted.

- **Payload fields are the flat data the event carries**, described as a mapping *off* those inputs:
  - `from:` names which input to read (it must be one you declared with `input`/`optional_input`).
  - `attr:` names the attribute to read off that input.
  - `required_payload` vs. `optional_payload` sets whether the field is a **guaranteed** part of the payload. That `required` flag is stored in the schema and is part of the event's fingerprint, so changing it changes the contract.

So `required_payload :email, from: :lead, attr: :email` means: *"the event carries an `email` field, and it comes from `lead.email`."* This gem **records that mapping** in the schema — it does not read your objects. The mapping is applied at runtime by the publisher that `event_engine` supplies (see below).

### Reserved names

Compilation rejects definitions that use names owned by the event envelope:

- **Payload field names** may not be any of:
  `event_name`, `event_type`, `event_version`, `occurred_at`, `created_at`, `updated_at`, `published_at`, `metadata`, `idempotency_key`, `attempts`, `dead_lettered_at`, `aggregate_type`, `aggregate_id`, `aggregate_version`.
- **Input names** may not collide with the envelope keys:
  `event_version`, `occurred_at`, `metadata`, `idempotency_key`, `aggregate_type`, `aggregate_id`, `aggregate_version`.

A payload field must also have a `from:` that references a declared input, and each event name must be snake_case.

### 2. Inspect the compiled schema

Every definition compiles to a `Schema` value object:

```ruby
schema = LeadCreated.schema

schema.event_name       # => :lead_created
schema.required_inputs  # => [:lead]
schema.optional_inputs  # => [:campaign]
schema.fingerprint      # => "…sha256 of the event's structure…"
schema.to_h             # => plain data hash (JSON-safe)
schema.to_ruby          # => a Ruby source string that rebuilds the Schema
```

The fingerprint is a stable hash of the event's **structure** (name, type, inputs, payload fields) — incidental fields like `domain` don't change it, so a matching fingerprint means a matching contract.

### 3. Generate a whole lifecycle (optional)

`LifecycleDefinition` stamps out one snake_case event per verb from a shared base, with per-verb overrides via `on`:

```ruby
class ExportCsv < EventEngine::LifecycleDefinition
  subject    :export_csv
  event_type :product

  input :export
  required_payload :format, from: :export, attr: :format

  lifecycle :started, :completed, :failed

  on :failed do
    input :error
    required_payload :error_class, from: :error, attr: :class
  end
end

ExportCsv.generated_events.map { |event| event.schema.event_name }
# => [:export_csv_started, :export_csv_completed, :export_csv_failed]
```

### 4. Build a domain pack

`DomainPackBuild.run` compiles a set of definitions and writes two files next to each other:

```ruby
EventEngine::DomainPackBuild.run(
  [LeadCreated],
  helper_path: "app/generated/marketing_events.rb",
  root_module: "MarketingEvents"
)
```

This produces:

- **`marketing_events.rb`** — a flat helper module. Each event becomes a typed method whose arguments are the event's **inputs** (plus the envelope keys), and which emits through the publisher port:

  ```ruby
  module MarketingEvents
    def self.schema_path
      File.expand_path("schema.json", __dir__)
    end

    def self.lead_created(lead:, campaign: nil, event_version: nil, occurred_at: nil,
                          metadata: nil, idempotency_key: nil, aggregate_type: nil,
                          aggregate_id: nil, aggregate_version: nil)
      EventEngine::Definition.publisher.publish(
        :lead_created,
        domain: :marketing,
        inputs: { lead: lead, campaign: campaign },
        event_version: event_version,
        occurred_at: occurred_at,
        # …remaining envelope keys…
      )
    end
  end
  ```

  Note the helper forwards the **raw input objects** under `inputs:`. The `from:`/`attr:` payload mapping is not applied here — it lives in the schema and is applied downstream.

- **`schema.json`** — the canonical, committed schema for the pack (one entry per event, each carrying its fingerprint). This file is authoritative in production; it is generated, not hand-edited.

### 5. Emit through a publisher

The generated helpers call `EventEngine::Definition.publisher.publish`. Out of the box the publisher is a `NullPublisher` that raises until one is configured:

```ruby
MarketingEvents.lead_created(lead: some_lead)
# => EventEngine::Definition::PublisherNotConfigured

EventEngine::Definition.publisher = my_publisher   # any object with #publish(event_name, **envelope)
```

**What the inputs look like.** An input is just whatever object your code already has — the payload mapping decides which attributes get read off it. For `LeadCreated`, `lead` needs to answer `#email` (because of `attr: :email`):

```ruby
lead = Lead.new(email: "ada@example.com")   # a record, struct, or any object responding to #email

MarketingEvents.lead_created(lead: lead)
# hands the publisher:
#   publish(:lead_created,
#           domain: :marketing,
#           inputs: { lead: lead, campaign: nil },
#           event_version: nil, occurred_at: nil, … )
```

The publisher then applies the schema's payload mapping (`email` ← `lead.email`) to build the event it stores and dispatches. This gem describes the contract; it never reaches into your objects itself.

## How it fits with `event_engine`

This gem defines and generates; `event_engine` runs. The seam between them is the **publisher port** (`EventEngine::Definition.publisher`):

```
this gem                                    event_engine (host runtime)
────────────────────────────────           ──────────────────────────────
EventDefinition DSL                          registers as the publisher
        │ compile                            ────────────────────►
        ▼                                    reads inputs via the schema's
generated helper  ──publish(event)──►        from:/attr: mapping, then
+ committed schema.json                       dispatches, persists, brokers…
```

A domain pack depends only on `event_engine-definition` to declare its events and build its helper file. In an app that also has `event_engine` installed, `event_engine` provides a real publisher adapter and assigns it to `EventEngine::Definition.publisher`, so calling a generated helper hands the event to the full runtime. Nothing in this gem knows how events are dispatched — that decision lives entirely in `event_engine`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then:

- `rake test` — run the test suite
- `bin/console` — an interactive prompt with the gem loaded

## License

Available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
