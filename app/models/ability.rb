class Ability
  include CanCan::Ability

  def initialize(user)
    if user && user.root?
      can :manage, :all
    elsif user
      manage_by_credentials(user)
      user.managed_group.users.each do |u|
        manage_by_credentials(u)
      end if user.managed_group(:force_update)
    end
  end

  def manage_by_credentials(user)
    user.credentials(:force_update).each do |c|
      can :manage, c.document_type.constantize
    end
  end
end
