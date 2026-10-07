module Persistence
  # Implementa Repositories::SubscriptionRepository.
  class SubscriptionRepository
    # Uma assinatura ativa por usuário é garantido por índice parcial único no
    # banco. Este método só localiza.
    def find(id)
      record = SubscriptionRecord.includes(:plan_record).find_by(id: id)
      record && RecordMapper.record_to_subscription(record)
    end

    def find_active_by_user(user_id)
      record = SubscriptionRecord.includes(:plan_record).active.find_by(user_id: user_id)
      record && RecordMapper.record_to_subscription(record)
    end

    def save(subscription)
      record = SubscriptionRecord.find_by(id: subscription.id) || SubscriptionRecord.new
      record.user_id = subscription.user_id
      record.plan_id = plan_record_for(subscription.plan).id
      record.asaas_subscription_id = subscription.provider_subscription_id
      record.status = subscription.status.to_s
      record.current_period_ends_at = subscription.current_period_ends_at
      record.cancelled_at = subscription.cancelled_at
      record.save!
      RecordMapper.record_to_subscription(record)
    end

    private

    # O Plan agregado não guarda id, então resolve pelo code, que é único.
    def plan_record_for(plan)
      PlanRecord.find_by!(code: plan.code.to_s)
    end
  end
end
