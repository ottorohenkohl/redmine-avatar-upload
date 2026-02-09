require_relative 'lib/redmine_avatar_upload/hooks'

Redmine::Plugin.register :redmine_avatar_upload do
  name 'Avatar Upload'
  author 'Otto Rohenkohl'
  version '0.0.1'

  permission :upload_own_avatar, { avatar_uploads: [:new, :create] }, public: true
  menu :account_menu, :avatar_upload, { controller: 'avatar_upload', action: 'new' }, caption: 'Avatar hochladen'
end
