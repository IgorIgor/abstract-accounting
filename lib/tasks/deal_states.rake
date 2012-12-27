namespace :deal_states do
  task add_state: :environment do
    get_state = lambda do |obj|
      return Helpers::Statable::UNKNOWN if obj.deal.nil? || obj.deal.deal_state.nil?
      if obj.deal.deal_state.in_work?
        return Helpers::Statable::INWORK
      elsif obj.deal.deal_state.closed? && obj.deal.to_facts.size == 0
        return Helpers::Statable::CANCELED
      elsif obj.deal.deal_state.closed? && obj.deal.to_facts.size == 1 &&
          obj.deal.to_facts.where{amount == 1.0}.size == 1
        return Helpers::Statable::APPLIED
      elsif obj.deal.deal_state.closed? && obj.deal.to_facts.size == 2 &&
          obj.deal.to_facts.where{amount == -1.0}.size == 1
        return Helpers::Statable::REVERSED
      end
      Helpers::Statable::UNKNOWN
    end
    begin
      ActiveRecord::Base.transaction do
        Waybill.all.each do |waybill|
          state = get_state.call(waybill)
          waybill.deal.deal_state.state = state
          waybill.deal.deal_state.save!
        end
        Allocation.all.each do |allocation|
          state = get_state.call(allocation)
          allocation.deal.deal_state.state = state
          allocation.deal.deal_state.save!
        end
      end
    rescue Exception => e
      p e.message
    end
  end
end