module Api
  module V1
    module Serializers
      class InstitutionSerializer
        def self.call(institution)
          {
            id: institution.id,
            legal_name: institution.legal_name,
            trade_name: institution.trade_name,
            slug: institution.slug,
            description: institution.description,
            cnpj: institution.cnpj&.formatted,
            address: serialize_address(institution.address),
            contact_email: institution.contact_email,
            mobile_phone: institution.mobile_phone,
            registration_status: institution.registration_status.to_s,
            verified: institution.registration_approved?,
            status: institution.status.to_s,
            accepts_donations: institution.accepts_donations?,
            withdraws_on_its_own: institution.withdraws_on_its_own?
          }
        end

        def self.serialize_address(address)
          return nil if address.nil?

          {
            street: address.street,
            number: address.number,
            neighborhood: address.neighborhood,
            postal_code: address.postal_code,
            complement: address.complement,
            city: address.city
          }
        end

        private_class_method :serialize_address
      end
    end
  end
end
