class AvatarUploadController < ApplicationController
  before_action :require_login
  before_action :authorize

  SHARE_ROOT = '/mnt/redmine_avatars'.freeze

  MAX_BYTES_MiB  = 5
  MAX_BYTES  = MAX_BYTES_MiB * 1024 * 1024

  def new
  end

  def create
    file = params[:jpeg]

    unless file.respond_to?(:original_filename)
      return render_error message: 'Keine Datei übergeben.'
    end

    if file.size.to_i <= 0 || file.size.to_i > MAX_BYTES
      return render_error message: "Datei zu groß oder leer (max #{MAX_BYTES_MiB} MB)."
    end

    unless file.content_type.to_s.downcase.in?(%w[image/jpeg image/jpg])
      return render_error message: 'Nur JPEG erlaubt.'
    end

    io = file.tempfile
    io.rewind
    head = io.read(2)

    return render_error(message: 'Datei ist kein JPEG.') unless head&.bytes == [0xFF, 0xD8]

    io.rewind

    dest_path = File.join(SHARE_ROOT, "#{User.current.login.to_s}.jpg")
    tmp_path = File.join(SHARE_ROOT, ".#{User.current.login.to_s}.jpg.uploading-#{Process.pid}-#{SecureRandom.hex(6)}")

    begin
      File.open(tmp_path, 'wb', 0o660) do |out|
        IO.copy_stream(io, out)

        out.fsync rescue nil
      end

      File.rename(tmp_path, dest_path)
    rescue => e
      FileUtils.rm_f(tmp_path) rescue nil

      return render_error message: "Speichern fehlgeschlagen: #{e.class}: #{e.message}"
    end

    flash[:notice] = "Das Profilbild wurde gespeichert, aber die Übernahme dauert unter Umständen einen Moment."

    redirect_to action: :new
  end

  private

  def authorize(ctrl = params[:controller], action = params[:action], global = false)
    allowed = User.current.allowed_to?(:upload_own_jpeg, nil, global: true)

    render_403 unless allowed
  end
end