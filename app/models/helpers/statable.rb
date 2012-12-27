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
        scope = self.joins{deal.deal_state}
        scope.where do
          scope_where = nil
          if filter[:inwork]
            scope_where = (deal.deal_state.state == INWORK)
          end
          if filter[:canceled]
            canceled = (deal.deal_state.state == CANCELED)
            scope_where = scope_where ? scope_where | canceled : canceled
          end
          if filter[:applied]
            applied = (deal.deal_state.state == APPLIED)
            scope_where = scope_where ? scope_where | applied : applied
          end
          if filter[:reversed]
            reversed = (deal.deal_state.state == REVERSED)
            scope_where = scope_where ? scope_where | reversed : reversed
          end
          scope_where
        end
      end
      alias_method :statable_search, :search_by_states
    end

    UNKNOWN = 0
    INWORK = 1
    CANCELED = 2
    APPLIED = 3
    REVERSED = 4

    def open_state
      self.deal.create_deal_state!(state: INWORK) if self.deal.deal_state.nil?
    end

    def state
      return UNKNOWN if self.deal.nil? || self.deal.deal_state.nil?
      self.deal.deal_state.state
    end

    def cancel
      if self.state == INWORK
        return run_callbacks :cancel do
          self.deal.deal_state.close
          self.deal.deal_state.update_attributes(state: CANCELED)
        end
      end
      false
    end

    def apply
      if self.state == INWORK
        return run_callbacks :apply do
          self.deal.deal_state.close
          self.deal.deal_state.update_attributes(state: APPLIED)
        end
      end
      false
    end

    def reverse
      if self.state == APPLIED
        return run_callbacks :reverse do
          self.deal.deal_state.update_attributes(state: REVERSED)
        end
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
