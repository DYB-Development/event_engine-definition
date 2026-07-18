# EventEngine::Definition — examples

Each example follows the same three beats: the **data** you already have, the **event** you define, and the **call** you make. For the full DSL reference and how this plugs into `event_engine`, see the [README](../README.md).

The `SalesEvents` / `ProductEvents` modules below are the helpers produced by generating the pack — the `rake event_engine:definition:dump` build step in the README. These examples assume that step has already run, so they focus on defining the event and calling it.

## An event built from multiple inputs

You have an order and the customer who placed it — and maybe a coupon:

```ruby
order    = Order.create!(total_cents: 4_200)   # => #<Order id: 100, total_cents: 4200, …>
customer = order.customer                       # => #<Customer id: 7, email: "ada@example.com", …>
coupon   = Coupon.find_by(code: "WELCOME")     # optional — may be nil
```

Define an event that captures a consistent slice of each input:

```ruby
class OrderPlaced < EventEngine::EventDefinition
  event_name :order_placed
  event_type :domain
  domain     :sales

  input :order
  input :customer
  optional_input :coupon

  required_payload :order_id,       from: :order,    attr: :id
  required_payload :total_cents,    from: :order,    attr: :total_cents
  required_payload :customer_id,    from: :customer, attr: :id
  required_payload :customer_email, from: :customer, attr: :email
  optional_payload :coupon_code,    from: :coupon,   attr: :code
end
```

Emit it — pass each input; optional ones you can leave off:

```ruby
SalesEvents.order_placed(order: order, customer: customer, coupon: coupon)
# or, with no coupon:
SalesEvents.order_placed(order: order, customer: customer)
```

Captured:

```ruby
{
  order_id:       100,
  total_cents:    4200,
  customer_id:    7,
  customer_email: "ada@example.com",
  coupon_code:    "WELCOME"
}
```

## A lifecycle: one definition, an event per step

You have a long-running job:

```ruby
export = Export.create!(format: "csv")   # => #<Export id: 9, format: "csv", …>
```

`LifecycleDefinition` stamps out one event per verb from a shared base, and `on` layers extra data onto a single step:

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
```

That gives you three events — `export_csv_started`, `export_csv_completed`, and `export_csv_failed` — each carrying `format`, and the failed one also carrying `error_class`.

Once the pack is generated, emit the step that happened:

```ruby
ProductEvents.export_csv_failed(export: export, error: some_error)
```

Captured:

```ruby
{ format: "csv", error_class: "Timeout::Error" }
```
