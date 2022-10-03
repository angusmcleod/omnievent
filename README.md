# OmniEvent (In Development)

Manage events from any calendar, event discovery, event ticketing, event management, social network or video conferencing provider in ruby.

This gem is significantly inspired by, and structurally similar to, [OmniAuth](https://github.com/omniauth/omniauth). It is the result of research conducted by Pavilion in the [NGI DAPSI program](https://dapsi.ngi.eu/), specifically:

> A study of the existing calendar event standards, and attempts to develop a standard calendar event data model, including a comparative analysis of the current data models of popular event-related services.

The research and its associated data will be made publicly available in the coming months, along with code documentation (using YARD) and a product landing page.

## Installation

The gem is still being developed and is not yet ready for installation. You can use it locally (see below).

## Usage (development only)

Please note that the gem is still being developed and is not yet ready for production use.

### Configure Providers

First, you need to configure at least one event provider strategy using the `OmniEvent::Builder`.
The gem comes packaged with the `developer` provider strategy, which merely demonstrates
the functionality, and does not connect to any real provider. All real provider
strategies will be packaged as separate gems, similar to the OmniAuth gem.

```
OmniEvent::Builder.new do
  provider :developer
end
```

#### Authorization

Authorization is handled by each provider strategy according to the authorization
mechanisms of that provider. Check the provider gem's readme to see what options
need to be set during configuration to ensure your connection to the provider
is authorized.

### Event Methods

OmniEvent has various event methods to provide access to events from one or more
of your configured providers. All event methods are available as class methods
on the `OmniEvent` module.

#### List Events (`list_events`)

List events from a configured provider.

```
OmniEvent.list_events(:developer, opts)
```

##### Options

`from_time`: List events from time.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Omnievent project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/paviliondev/omnievent/blob/main/CODE_OF_CONDUCT.md).
