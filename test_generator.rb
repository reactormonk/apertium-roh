require 'minitest/autorun'
require 'minitest/spec'
require_relative 'generator'

describe Verb do
  [
   ["abusar", "abus", "a"],
   ["giaschair", "giasch", "ai"],
   ["cuir", "cu", "i"],
   ["coier", "coi", "e"]
  ].each do |(verb, root, type)|

    describe "describe the verb #{verb}" do
      let(:target) { Verb.new(verb) }

      it "should return the root" do
        target.root.must_equal root
      end

      it "should find the type" do
        target.type.must_equal type
      end
    end
  end
end

describe VCVerb do
  [
   ["ruassar", "ua", "uau", "ruass", "ruauss"],
   ["manar", "a", "ai", "man", "main"],
   ["baiver", "a", "ai", "bav", "baiv"],
   ["suandar", "ua", "uo", "suand", "suond"],
   ["taisser", "e", "ai", "tess", "taiss"],
   ["luar", "u", "ieu", "lu", "lieu"],
   ["gratular", "", "esch", "gratul", "gratulesch"],
   ["finir", "", "esch", "fin", "finesch"],
   ["sclauder", "u", "au", "sclud", "sclaud"],
   ["quescher", "cu", "que", "cusch", "quesch"],
   ["porscher", "u", "o", "pursch", "porsch"]
  ].each do |(verb, from, to, root, changed)|
    describe "describe the verb #{verb}" do
      let(:target) { VCVerb.new(verb, from, to) }

      it "should return the root" do
        target.root.must_equal root
      end

      it "should find the changed root" do
        target.changed.must_equal changed
      end
    end
  end
end
