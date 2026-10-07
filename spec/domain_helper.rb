require "bigdecimal"

# Loads app/domain without booting Rails, without a database and without
# Bundler. That is the point of keeping the domain framework free: the suite
# runs anywhere Ruby runs.
#
# Order matters, because some constants are evaluated at load time:
# Donation::MINIMUM_DONATION calls Money.build, and Percentage raises
# InvalidSplit from its constructor.
DOMAIN_ROOT = File.expand_path("../app/domain", __dir__).freeze

DOMAIN_FILES = %w[
  errors/domain_error
  errors/invalid_institution
  errors/invalid_donation
  errors/invalid_split
  errors/invalid_subscription
  value_objects/money
  value_objects/percentage
  value_objects/cpf_cnpj
  value_objects/pix_key
  value_objects/external_reference
  value_objects/address
  value_objects/charge_snapshot
  value_objects/subaccount_snapshot
  value_objects/transfer_snapshot
  value_objects/subscription_snapshot
  entities/donation_split
  entities/institution
  entities/donation
  entities/plan
  entities/subscription
  entities/payout
  entities/webhook_event
  services/split_policy
  services/settlement_plan
].freeze

DOMAIN_FILES.each { |path| require File.join(DOMAIN_ROOT, path) }
