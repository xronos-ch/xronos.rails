# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here.

    # permissions for every user, even if not logged in
    can :read, :all
    cannot :read, [UserProfile]
    cannot :read, Article
    can :read, Article, published?: true
    can :feed, Article
    can :search, :all
    can :calibrate, :all
    can :calibrate_multi, :all
    can :calibrate_sum, :all

    # additional permissions for logged in users (they can manage their posts)
    if user.present?
      can :create, :all
      can [:read, :update], [UserProfile], :user_id => user.id
      if user.admin?  # additional permissions for administrators
        can :manage, :all
        can :duplicates, :all
      end
    end

    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  end
end
