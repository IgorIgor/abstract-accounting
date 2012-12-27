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

        delegate :can_apply?, :can_cancel?, :can_reverse?, to: :deal, allow_nil: true
        delegate :in_work?, to: :deal

        after_save :open_state
        define_callbacks :apply, :cancel, :reverse, only: [:before, :after],
                         terminator: "result == false"

        custom_search(:states) do |filter = []|
          return scoped if filter.empty?
          return scoped if filter.count == 4 &&
                           filter.sort == [INWORK,APPLIED,CANCELED,REVERSED].sort
          scope = self.joins{deal.deal_state}
          scope.where do
            filter.inject(nil) do |scope_where, value|
              tmp = case Converter.int(value)
                      when INWORK
                        (deal.deal_state.state == INWORK)
                      when APPLIED
                        (deal.deal_state.state == APPLIED)
                      when CANCELED
                        (deal.deal_state.state == CANCELED)
                      when REVERSED
                        (deal.deal_state.state == REVERSED)
                      else nil
                    end
              if tmp
                scope_where ? (scope_where | tmp) : tmp
              else
                scope_where
              end
            end
          end
        end

        custom_sort(:state) do |direction|
          joins{deal.deal_state}.order{deal.deal_state.state.__send__(direction)}
        end
      end

      [:apply, :cancel, :reverse].each do |value|
        define_method "after_#{value}".to_sym do |*filters|
          set_callback value, :after, *filters
        end
        define_method "before_#{value}".to_sym do |*filters|
          set_callback value, :before, *filters
        end
      end
    end

    UNKNOWN = DealState::UNKNOWN
    INWORK = DealState::INWORK
    CANCELED = DealState::CANCELED
    APPLIED = DealState::APPLIED
    REVERSED = DealState::REVERSED

    def state
      return UNKNOWN if self.deal.nil? || self.deal.deal_state.nil?
      self.deal.deal_state.state
    end

    def unknown?
      self.state == UNKNOWN
    end

    def cancel
      if self.can_cancel?
        return run_callbacks :cancel do
          self.deal.cancel
        end
      end
      false
    end

    def apply
      if self.can_apply?
        return run_callbacks :apply do
          self.deal.apply
        end
      end
      false
    end

    def reverse
      if self.can_reverse?
        return run_callbacks :reverse do
          self.deal.reverse
        end
      end
      false
    end

    private
      def open_state
        self.deal.create_deal_state! if self.deal.deal_state.nil?
      end
  end
end
