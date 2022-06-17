# frozen_string_literal: true

RSpec.describe OmniEvent::Strategy do
  describe ".default_options" do
    it "is inherited from a parent class" do
      superklass = Class.new
      superklass.send :include, OmniEvent::Strategy
      superklass.configure do |c|
        c.foo = "bar"
      end

      klass = Class.new(superklass)
      expect(klass.default_options.foo).to eq("bar")
    end
  end

  describe ".configure" do
    subject do
      c = Class.new
      c.send(:include, OmniEvent::Strategy)
    end

    context "when block is passed" do
      it "allows for default options setting" do
        subject.configure do |c|
          c.wakka = "doo"
        end
        expect(subject.default_options["wakka"]).to eq("doo")
      end

      it "works when block doesnt evaluate to true" do
        environment_variable = nil
        subject.configure do |c|
          c.abc = "123"
          c.hgi = environment_variable
        end
        expect(subject.default_options["abc"]).to eq("123")
      end
    end

    it "takes a hash and deep merges it" do
      subject.configure abc: { def: 123 }
      subject.configure abc: { hgi: 456 }
      expect(subject.default_options["abc"]).to eq({ "def" => 123, "hgi" => 456 })
    end
  end

  it "raises a NotImplementedError when strategy has not implemented interface methods" do
    strategy = Class.new
    strategy.send(:include, OmniEvent::Strategy)
    expect { strategy.new.send("event") }.to raise_error(NotImplementedError)
    expect { strategy.new.send("event_list") }.to raise_error(NotImplementedError)
  end
end
