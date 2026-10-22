module Persistence
  # Implementa Repositories::PostRepository.
  class PostRepository
    def find(id)
      record = PostRecord.find_by(id: id)
      record && RecordMapper.record_to_post(record)
    end

    def list_feed(institution_id, limit: nil, offset: nil)
      scope = PostRecord.in_feed.where(institution_id: institution_id)
      scope = scope.limit(limit) if limit
      scope = scope.offset(offset) if offset
      scope.map { |record| RecordMapper.record_to_post(record) }
    end

    def save(post)
      record = PostRecord.find_or_initialize_by(id: post.id)
      RecordMapper.post_to_record(post, record)
      record.save!
      RecordMapper.record_to_post(record)
    end
  end
end
