# Two different mechanisms live here on purpose. Internal transfers require
# the destination account to be linked to ours, which is only true for
# subaccounts we created. Outbound pix transfers have no such requirement
# and are what the pix_payout strategy uses to pay institutions without a
# subaccount.
class TransferService
  # @param pix_key [PixKey]
  # @return [TransferSnapshot]
  def send_pix(amount:, pix_key:, reference:, scheduled_for: nil)
    raise NotImplementedError
  end

  # @param wallet_id [String] a linked subaccount wallet
  # @return [TransferSnapshot]
  def send_to_wallet(amount:, wallet_id:, reference:, scheduled_for: nil)
    raise NotImplementedError
  end

  # @return [TransferSnapshot, nil]
  def find_transfer(provider_transfer_id)
    raise NotImplementedError
  end
end
