require_relative "../domain_helper"

RSpec.describe "architecture boundaries" do
  PORTS_ROOT = File.expand_path("../../app/ports", __dir__).freeze
  APP_ROOT = File.expand_path("../..", __dir__).freeze

  FORBIDDEN_IN_DOMAIN = /\b(
    ActiveRecord | ActiveSupport | ActionController | ActionDispatch |
    ApplicationRecord | ApplicationController |
    Rails\.[a-z] |
    \.validates | \.belongs_to | \.has_many | \.before_save | \.after_commit |
    Time\.current | Date\.current | 1\.day |
    \.present\? | \.blank\? | \.to_sentence | \.deep_symbolize_keys
  )/x

  def domain_files
    Dir[File.join(DOMAIN_ROOT, "**", "*.rb")]
  end

  def port_files
    Dir[File.join(PORTS_ROOT, "**", "*.rb")]
  end

  it "has domain files to check" do
    expect(domain_files).not_to be_empty
  end

  it "keeps the domain free of Rails and ActiveSupport" do
    offenders = domain_files.select { |file| File.read(file).match?(FORBIDDEN_IN_DOMAIN) }

    expect(offenders).to be_empty,
      "app/domain must stay framework free. Offending files:\n#{offenders.join("\n")}"
  end

  it "keeps the domain free of require statements" do
    offenders = domain_files.select { |file| File.read(file).match?(/^\s*require\b/) }

    expect(offenders).to be_empty,
      "app/domain must not require anything. Offending files:\n#{offenders.join("\n")}"
  end

  it "does not leak provider vocabulary into the domain" do
    leaks = domain_files.select { |file|
      File.read(file).match?(/\b(asaas|walletId|percentualValue|fixedValue|netValue|cus_|pay_)\b/i)
    }

    expect(leaks).to be_empty,
      "provider concepts belong in adapters. Offending files:\n#{leaks.join("\n")}"
  end

  it "has ports to check" do
    expect(port_files).not_to be_empty
  end

  it "keeps ports free of HTTP and of implementations" do
    offenders = port_files.select { |file|
      content = File.read(file)
      content.match?(/Net::HTTP|Faraday|HTTParty|\.post\(|\.get\(/) && !content.include?("def ")
    }

    expect(offenders).to be_empty,
      "ports only declare signatures. Offending files:\n#{offenders.join("\n")}"
  end

  it "has an application layer that talks only to ports and domain" do
    files = Dir[File.join(APP_ROOT, "app/application/**/*.rb")]
    offenders = files.select { |file| File.read(file).include?("ActiveRecord") }

    expect(offenders).to be_empty,
      "app/application must not touch ActiveRecord. Offending files:\n#{offenders.join("\n")}"
  end
end
