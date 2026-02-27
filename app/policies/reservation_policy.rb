class ReservationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.admin? || record.user == user
  end

  def create?
    user.present?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin? || (record.user == user && record.status == "confirmed")
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
end
