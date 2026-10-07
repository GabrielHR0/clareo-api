class SettlementPlan
  class << self
    def call(institution:, amount:, policy: SplitPolicy.default)
      unless institution.accepts_donations?
        raise InvalidDonation, "institution cannot accept donations"
      end
      unless policy.accepts?(amount)
        raise InvalidDonation, "amount must be at least #{policy.minimum_donation}"
      end

      platform = policy.percentage_for(amount)
      institution_share = platform.complement

      [
        DonationSplit.for_institution(institution: institution, percentage: institution_share),
        DonationSplit.for_platform(percentage: platform)
      ]
    end
  end
end
