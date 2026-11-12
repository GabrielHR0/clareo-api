module Api
  module V1
    module Serializers
      class DocumentSerializer
        def self.call(document)
          {
            id: document.id,
            kind: document.kind.to_s,
            kind_detail: document.kind_detail,
            number: document.number,
            issued_on: document.issued_on&.iso8601
          }
        end
      end
    end
  end
end
