# Prestação de contas de uma instituição em um período. Diferente do post, o
# relatório não é narrativa livre: o número é congelado a partir do razão e
# passa por revisão da plataforma antes de virar público.
#
# O ciclo é explícito:
#   draft -> submitted -> under_review -> approved -> published
#                         \-> changes_requested -> submitted
#
# Depois de submitted as entradas não mudam mais. Publicado, o relatório é
# imutável: correção é um novo relatório, não uma edição do que já foi prestado.
class AccountabilityReport
  STATUSES = %i[draft submitted under_review approved changes_requested published].freeze
  EDITABLE_STATUSES = %i[draft changes_requested].freeze

  attr_reader :id, :institution_id, :campaign_id, :title, :summary,
              :period_start, :period_end, :status, :submitted_at,
              :review_started_at, :approved_at, :published_at, :reviewer_id,
              :review_opinion, :review_notes, :entries

  class << self
    def build(institution_id:, title:, period_start:, period_end:, id: nil,
              campaign_id: nil, summary: nil, status: :draft, submitted_at: nil,
              review_started_at: nil, approved_at: nil, published_at: nil,
              reviewer_id: nil, review_opinion: nil, review_notes: nil,
              entries: [])
      new(
        id: id,
        institution_id: institution_id,
        campaign_id: campaign_id,
        title: title,
        summary: summary,
        period_start: period_start,
        period_end: period_end,
        status: status,
        submitted_at: submitted_at,
        review_started_at: review_started_at,
        approved_at: approved_at,
        published_at: published_at,
        reviewer_id: reviewer_id,
        review_opinion: review_opinion,
        review_notes: review_notes,
        entries: entries
      )
    end
  end

  def initialize(institution_id:, title:, period_start:, period_end:, id: nil,
                 campaign_id: nil, summary: nil, status: :draft,
                 submitted_at: nil, review_started_at: nil, approved_at: nil,
                 published_at: nil, reviewer_id: nil, review_opinion: nil,
                 review_notes: nil, entries: [])
    @id = id
    @institution_id = institution_id
    @campaign_id = campaign_id
    @title = presence(title, "title")
    @summary = normalize_optional(summary)
    @period_start = period_start
    @period_end = period_end
    @status = status.to_sym
    @submitted_at = submitted_at
    @review_started_at = review_started_at
    @approved_at = approved_at
    @published_at = published_at
    @reviewer_id = reviewer_id
    @review_opinion = normalize_optional(review_opinion)
    @review_notes = normalize_optional(review_notes)
    @entries = Array(entries).dup

    validate!
  end

  def draft?
    status == :draft
  end

  def submitted?
    status == :submitted
  end

  def under_review?
    status == :under_review
  end

  def approved?
    status == :approved
  end

  def changes_requested?
    status == :changes_requested
  end

  def published?
    status == :published
  end

  def editable?
    EDITABLE_STATUSES.include?(status)
  end

  def public?
    published?
  end

  def update_details!(title:, summary:, period_start:, period_end:, campaign_id: nil, entries: nil)
    ensure_editable!
    @title = presence(title, "title")
    @summary = normalize_optional(summary)
    @period_start = period_start
    @period_end = period_end
    @campaign_id = campaign_id
    @entries = Array(entries).dup unless entries.nil?
    validate!
    self
  end

  # O submit é o ponto em que o rascunho vira declaração. As entradas recebidas
  # aqui são a fotografia do período; depois disso a instituição não escolhe
  # mais o que entra ou sai.
  def submit!(entries:, at:)
    ensure_editable!
    raise InvalidAccountabilityReport, "summary is required before submission" if summary.nil?

    @entries = Array(entries).dup
    @status = :submitted
    @submitted_at = at
    @review_started_at = nil
    @approved_at = nil
    @published_at = nil
    @reviewer_id = nil
    @review_opinion = nil
    @review_notes = nil

    validate!
    @entries.freeze
    self
  end

  def start_review!(reviewer_id:, at:)
    require_status!(:submitted)
    raise InvalidAccountabilityReport, "reviewer is required" if reviewer_id.nil?

    @status = :under_review
    @reviewer_id = reviewer_id
    @review_started_at = at
    validate!
    self
  end

  def approve!(reviewer_id:, opinion:, at:)
    require_status!(:under_review)
    raise InvalidAccountabilityReport, "reviewer is required" if reviewer_id.nil?

    text = presence(opinion, "review opinion")
    @status = :approved
    @reviewer_id = reviewer_id
    @approved_at = at
    @review_opinion = text
    validate!
    self
  end

  def request_changes!(reviewer_id:, notes:, at:)
    require_status!(:under_review)
    raise InvalidAccountabilityReport, "reviewer is required" if reviewer_id.nil?

    text = presence(notes, "review notes")
    @status = :changes_requested
    @reviewer_id = reviewer_id
    @review_notes = text
    @review_started_at ||= at
    validate!
    self
  end

  def publish!(at:)
    require_status!(:approved)
    raise InvalidAccountabilityReport, "report must be approved before publishing" if approved_at.nil?

    @status = :published
    @published_at = at
    validate!
    self
  end

  def total_income
    entries.select(&:income?).reduce(Money.zero) { |sum, entry| sum + entry.amount }
  end

  def total_expense
    entries.select(&:expense?).reduce(Money.zero) { |sum, entry| sum + entry.amount }
  end

  def balance
    total_income - total_expense
  end

  def ==(other)
    other.is_a?(AccountabilityReport) && id == other.id && institution_id == other.institution_id
  end
  alias eql? ==

  def inspect
    "#<AccountabilityReport #{id} #{period_start}..#{period_end} #{status}>"
  end

  private

    def ensure_editable!
      return if editable?

      raise InvalidAccountabilityReport, "cannot edit a report in #{status}"
    end

    def require_status!(expected)
      return if status == expected

      raise InvalidAccountabilityReport, "cannot move report from #{status} to #{expected}"
    end

    def presence(value, field)
      text = value.to_s.strip
      raise InvalidAccountabilityReport, "#{field} cannot be blank" if text.empty?

      text
    end

    def normalize_optional(value)
      return nil if value.nil?

      text = value.to_s.strip
      text.empty? ? nil : text
    end

    def validate!
      raise InvalidAccountabilityReport, "institution is required" if institution_id.nil?

      presence(title, "title")
      validate_period!
      validate_status!
      validate_review_state!
      validate_entries!
    end

    def validate_period!
      raise InvalidAccountabilityReport, "period start is required" if period_start.nil?
      raise InvalidAccountabilityReport, "period end is required" if period_end.nil?

      return if period_start <= period_end

      raise InvalidAccountabilityReport, "period end cannot be before period start"
    end

    def validate_status!
      return if STATUSES.include?(status)

      raise InvalidAccountabilityReport, "status must be one of #{STATUSES.join(', ')}"
    end

    # Coerência mínima entre estado e marcos. Evita um relatório "published"
    # sem published_at, que pareceria público para a API e vazio para o banco.
    def validate_review_state!
      if %i[submitted under_review approved changes_requested published].include?(status)
        raise InvalidAccountabilityReport, "submitted_at is required after submission" if submitted_at.nil?
      end

      if %i[approved published].include?(status) && approved_at.nil?
        raise InvalidAccountabilityReport, "approved_at is required after approval"
      end

      return unless published? && published_at.nil?

      raise InvalidAccountabilityReport, "published_at is required after publishing"
    end

    def validate_entries!
      ids = entries.map(&:ledger_entry_id)
      if ids.uniq.size != ids.size
        raise InvalidAccountabilityReport, "a ledger entry cannot appear twice"
      end

      entries.each do |entry|
        if entry.institution_id != institution_id
          raise InvalidAccountabilityReport, "entry belongs to another institution"
        end

        if entry.posted_on < period_start || entry.posted_on > period_end
          raise InvalidAccountabilityReport, "entry is outside the report period"
        end

        if !campaign_id.nil? && entry.campaign_id != campaign_id
          raise InvalidAccountabilityReport, "entry belongs to another campaign"
        end
      end

      return unless %i[submitted under_review approved changes_requested published].include?(status)
      return unless entries.empty?

      raise InvalidAccountabilityReport, "a submitted report needs at least one entry"
    end
end
