module Repositories
class PostRepository
  # @return [Post, nil]
  def find(id)
    raise NotImplementedError
  end

  # @return [Array<Post>] o feed da instituição, do mais recente para o mais
  #   antigo. Oculto sai: esconder, não apagar, porque um post pode ter sido
  #   citado por um lançamento.
  def list_feed(institution_id, limit: nil, offset: nil)
    raise NotImplementedError
  end

  def save(post)
    raise NotImplementedError
  end
end
end
