module RedmineAvatarUpload
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_my_account, partial: 'avatar_upload/account_link'
  end
end