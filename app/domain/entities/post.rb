# Narrativa do feed. O post nunca é a fonte do número: ele pode citar
# lançamentos, mas o valor vive em LedgerEntry.
#
# Publicação é imediata e sem rascunho. Um post que precisa passar por
# aprovação é prestação de contas, e isso é AccountabilityReport, com o ciclo
# draft -> submitted -> under_review -> approved -> published. Confundir os
# dois dá à instituição a palavra final sobre o próprio número.
class Post
  TYPES = %i[update report].freeze

  STATUSES = %i[published hidden].freeze

  attr_reader :id, :institution_id, :title, :content, :post_type, :status,
              :published_at

  class << self
    def build(institution_id:, title:, content:, post_type: :update,
              published_at: nil, status: :published, id: nil)
      new(
        id: id,
        institution_id: institution_id,
        title: title,
        content: content,
        post_type: post_type,
        status: status,
        published_at: published_at
      )
    end
  end

  def initialize(id: nil, institution_id:, title:, content:, post_type: :update,
                 status: :published, published_at: nil)
    @id = id
    @institution_id = institution_id
    @title = presence(title, "title")
    @content = presence(content, "content")
    @post_type = post_type.to_sym
    @status = status.to_sym
    @published_at = published_at

    validate!
  end

  def published?
    status == :published
  end

  def hidden?
    status == :hidden
  end

  # Esconder, não apagar. O feed é público e um post pode ter sido citado por um
  # lançamento; removê-lo deixaria a referência órfã sem explicação.
  def hide!
    transition_to!(%i[published], :hidden)
    self
  end

  def publish!
    transition_to!(%i[hidden], :published)
    self
  end

  def ==(other)
    other.is_a?(Post) && id == other.id && institution_id == other.institution_id
  end
  alias eql? ==

  def inspect
    "#<Post #{post_type} #{title}>"
  end

  private

  def presence(value, field)
    text = value.to_s.strip
    raise InvalidPost, "#{field} cannot be blank" if text.empty?

    text
  end

  def validate!
    raise InvalidPost, "institution is required" if institution_id.nil?

    unless TYPES.include?(post_type)
      raise InvalidPost, "post_type must be one of #{TYPES.join(', ')}"
    end

    return if STATUSES.include?(status)

    raise InvalidPost, "status must be one of #{STATUSES.join(', ')}"
  end

  def transition_to!(allowed_from, target)
    unless allowed_from.include?(status)
      raise InvalidPost, "cannot move post from #{status} to #{target}"
    end

    @status = target
  end
end
