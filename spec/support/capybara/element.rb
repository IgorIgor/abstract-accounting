
module Capybara
  module Node
    class Element
      def click_and_wait
        click
        wait_until do
          session.evaluate_script 'jQuery.active == 0'
        end
      end
    end
  end
end
