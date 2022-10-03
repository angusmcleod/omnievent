# frozen_string_literal: true

RSpec.describe OmniEvent::Builder do
  before do
    OmniEvent::Strategies::ExampleStrategy.include OmniEvent::Strategy
  end

  it "translates a symbol to a constant" do
    expect(OmniEvent::Strategies).to receive(:const_get).with("ExampleStrategy", false).and_call_original
    described_class.new do
      provider :example_strategy
    end
  end

  it "raises a OmniEvent::MissingStrategy error if strategy is not present" do
    expect do
      described_class.new do
        provider :another_strategy
      end
    end.to raise_error(OmniEvent::MissingStrategy)
  end

  it "adds strategy procs to active_strategies" do
    described_class.new do
      provider :example_strategy
    end
    expect(OmniEvent.active_strategies.key?(OmniEvent::Strategies::ExampleStrategy)).to eq(true)
  end

  context "another strategy" do
    before do
      module OmniEvent
        module Strategies
          class AnotherStrategy; end
        end
      end
    end

    it "raises a OmniEvent::StrategyNotLoaded error if OmniEvent::Strategy is not included" do
      expect do
        described_class.new do
          provider :another_strategy
        end
      end.to raise_error(OmniEvent::StrategyNotIncluded)
    end

    context "with OmniEvent::Strategy included" do
      before do
        OmniEvent::Strategies::AnotherStrategy.include OmniEvent::Strategy
      end

      it "loads all strategies" do
        expect do
          described_class.new do
            provider :example_strategy
            provider :another_strategy
          end
          expect(OmniEvent.active_strategies.first).to be_kind_of(OmniEvent::Strategies::ExampleStrategy)
          expect(OmniEvent.active_strategies.second).to be_kind_of(OmniEvent::Strategies::AnotherStrategy)
        end
      end
    end
  end
end
