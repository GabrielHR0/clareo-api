# Uma linha congelada da prestação de contas. O relatório não aponta para o
# valor atual do lançamento: ele guarda o que foi efetivamente apresentado e
# aprovado, inclusive código e nome da conta naquele momento.
#
# A cópia é intencional. O ledger continua sendo a fonte viva; o snapshot é a
# fotografia publicada, e uma fotografia não muda quando o mundo muda.
class AccountabilityReportEntry
  KINDS = %i[income expense].freeze
  ORIGINS = %i[donation declared].freeze

  attr_reader :institution_id, :ledger_entry_id, :account_id, :account_code,
              :account_name, :campaign_id, :kind, :origin, :posted_on,
              :description, :amount

  class << self
    def from_ledger_entry(entry:, account:)
      new(
        institution_id: entry.institution_id,
        ledger_entry_id: entry.id,
        account_id: account.id,
        account_code: account.code,
        account_name: account.name,
        campaign_id: entry.campaign_id,
        kind: entry.kind,
        origin: entry.origin,
        posted_on: entry.posted_on,
        description: entry.description,
        amount: entry.amount
      )
    end

    def build(**attributes)
      new(**attributes)
    end
  end

  def initialize(institution_id:, ledger_entry_id:, account_id:, account_code:,
                 account_name:, kind:, origin:, posted_on:, amount:,
                 campaign_id: nil, description: nil)
    @institution_id = institution_id
    @ledger_entry_id = ledger_entry_id
    @account_id = account_id
    @account_code = account_code.to_s.strip
    @account_name = account_name.to_s.strip
    @campaign_id = campaign_id
    @kind = kind.to_sym
    @origin = origin.to_sym
    @posted_on = posted_on
    @description = normalize_description(description)
    @amount = Money.build(amount)

    validate!
  end

  def income?
    kind == :income
  end

  def expense?
    kind == :expense
  end

  def system?
    origin == :donation
  end

  def ==(other)
    other.is_a?(AccountabilityReportEntry) &&
      institution_id == other.institution_id &&
      ledger_entry_id == other.ledger_entry_id
  end
  alias eql? ==

  def inspect
    "#<AccountabilityReportEntry ledger=#{ledger_entry_id} #{kind} #{amount}>"
  end

  private

    def normalize_description(value)
      return nil if value.nil?

      text = value.to_s.strip
      text.empty? ? nil : text
    end

    def validate!
      raise InvalidAccountabilityReport, "institution is required" if institution_id.nil?
      raise InvalidAccountabilityReport, "ledger entry is required" if ledger_entry_id.nil?
      raise InvalidAccountabilityReport, "account is required" if account_id.nil?
      raise InvalidAccountabilityReport, "account code is required" if account_code.empty?
      raise InvalidAccountabilityReport, "account name is required" if account_name.empty?
      raise InvalidAccountabilityReport, "posted_on is required" if posted_on.nil?
      raise InvalidAccountabilityReport, "amount cannot be negative" if amount.negative?

      unless KINDS.include?(kind)
        raise InvalidAccountabilityReport, "kind must be one of #{KINDS.join(', ')}"
      end

      return if ORIGINS.include?(origin)

      raise InvalidAccountabilityReport, "origin must be one of #{ORIGINS.join(', ')}"
    end
end
