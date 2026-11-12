module Api
  module V1
    module Serializers
      class PostSerializer
        def self.call(post)
          {
            id: post.id,
            campaign_id: post.campaign_id,
            title: post.title,
            content: post.content,
            post_type: post.post_type.to_s,
            status: post.status.to_s,
            published_at: post.published_at&.iso8601
          }
        end
      end
    end
  end
end
