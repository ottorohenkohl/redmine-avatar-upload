require_relative 'lib/redmine_avatar_upload/hooks'

Redmine::Plugin.register :redmine_avatar_upload do
  name 'Avatar Upload'
  author 'Otto Rohenkohl'
  version '0.0.1'
end