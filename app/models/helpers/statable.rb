# Copyright (C) 2011 Sergey Yanovich <ynvich@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation; either version 3 of the
# License, or (at your option) any later version.
#
# Please see ./COPYING for details

module Helpers
  module Statable
    extend ActiveSupport::Concern

    module ClassMethods
      def act_as_statable
        include ActiveSupport::Callbacks

        after_save :open_state
        define_callbacks :apply, :cancel, :reverse, only: [:before, :after],
                         terminator: "result == false"
      end

      def after_apply(*filters)
        set_callback :apply, :after, *filters
      end

      def after_cancel(*filters)
        set_callback :cancel, :after, *filters
      end

      def after_reverse(*filters)
        set_callback :reverse, :after, *filters
      end

      def before_apply(*filters)
        set_callback :apply, :before, *filters
      end

      def before_reverse(*filters)
        set_callback :reverse, :before, *filters
      end

      def search_by_states(filter = {})
        return scoped if filter.empty?
        return scoped if filter.values.inject( true ){ |mem, value| mem && value }
        scope = self.joins{deal.deal_state}.joins{deal.to_facts.outer}
        scope = scope.where do
          scope_where = nil
          if filter[:inwork]
            scope_where = (deal.deal_state.closed == nil)
          end
          if filter[:applied] || filter[:canceled] || filter[:reversed]
            reversed = ((deal.deal_state.closed != nil))
            scope_where = scope_where ? scope_where | reversed : reversed
          end
          scope_where
        end
        group_by = self.column_names.map{ |item| "#{self.table_name}.#{item}" }
        group_by += scope.order_values.map{ |item| item.split(' ')[0] }
        scope = scope.group{group_by}
        scope_having = []
        if filter[:inwork] || filter[:canceled]
          scope_having<<'SUM(facts.amount) IS NULL'
        end
        if filter[:applied]
          scope_having = scope_having<<'SUM(facts.amount) = 1'
        end
        if filter[:reversed]
          scope_having = scope_having<<'SUM(facts.amount) = 0'
        end
        scope.having(scope_having.join(' OR '))
      end
      alias_method :statable_search, :search_by_states
    end

    UNKNOWN = 0
    INWORK = 1
    CANCELED = 2
    APPLIED = 3
    REVERSED = 4

    def open_state
      self.deal.create_deal_state! if self.deal.deal_state.nil?
    end

    def state
      return UNKNOWN if self.deal.nil? || self.deal.deal_state.nil?
      if self.deal.deal_state.in_work?
        return INWORK
      elsif self.deal.deal_state.closed? && self.deal.to_facts.size == 0
        return CANCELED
      elsif self.deal.deal_state.closed? && self.deal.to_facts.size == 1 &&
          self.deal.to_facts.where{amount == 1.0}.size == 1
        return APPLIED
      elsif self.deal.deal_state.closed? && self.deal.to_facts.size == 2 &&
          self.deal.to_facts.where{amount == -1.0}.size == 1
        return REVERSED
      end
      UNKNOWN
    end

    def cancel
      if self.state == INWORK
        return run_callbacks :cancel do
          self.deal.deal_state.close
        end
      end
      false
    end

    def apply
      if self.state == INWORK
        return run_callbacks :apply do
          self.deal.deal_state.close
        end
      end
      false
    end

    def reverse
      if self.state == APPLIED
        return run_callbacks :reverse
      end
      false
    end

    def can_apply?
      self.state == INWORK
    end

    def can_cancel?
      self.state == INWORK
    end

    def can_reverse?
      self.state == APPLIED
    end
  end
end
