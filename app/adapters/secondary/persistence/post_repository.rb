module Persistence
  # Implementa Repositories::PostRepository.
  class PostRepository
    def find(id)
      record = PostRecord.find_by(id: id)
      record && RecordMapper.record_to_post(record)
    end

    def list_feed(institution_id, campaign_id: nil, limit: nil, offset: nil)
      scope = PostRecord.in_feed.where(institution_id: institution_id)
      scope = scope.for_campaign(campaign_id) if campaign_id
      scope = scope.limit(limit) if limit
      scope = scope.offset(offset) if offset
      scope.map { |record| RecordMapper.record_to_post(record) }
    end

    def save(post)
      record = if post.id.nil?
        PostRecord.new
      else
        PostRecord.find_by!(id: post.id, institution_id: post.institution_id)
      end
      RecordMapper.post_to_record(post, record)
      record.save!
      RecordMapper.record_to_post(record)
    end
  end
end
