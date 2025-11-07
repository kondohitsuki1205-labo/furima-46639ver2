module ApplicationHelper
  def display_nickname(user)
    user.nickname.presence || 'ユーザー'
  end
end
