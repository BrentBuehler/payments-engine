class Transaction < ApplicationRecord
    belongs_to :account

    def mark_as_disputed
        self.update_attribute(:is_disputed, true)
    end

    def resolve_dispute
        self.update_attribute(:is_disputed, false)
    end
end
