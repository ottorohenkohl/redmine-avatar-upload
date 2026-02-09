class AvatarUploadController < ApplicationController
  before_action :require_login
  before_action :authorize

  SHARE_ROOT = '/mnt/redmine_avatars'.freeze  # <- dein gemountetes Share
  MAX_BYTES  = 5 * 1024 * 1024                # 5 MB

  def new
  end

  def create
    file = params[:jpeg]
    unless file.respond_to?(:original_filename)
      return render_error message: 'Keine Datei übergeben.'
    end

    if file.size.to_i <= 0 || file.size.to_i > MAX_BYTES
      return render_error message: "Datei zu groß oder leer (max #{MAX_BYTES / 1024 / 1024} MB)."
    end

    # Content-Type ist nicht vertrauenswürdig, aber als erster Filter ok:
    unless file.content_type.to_s.downcase.in?(%w[image/jpeg image/jpg])
      return render_error message: 'Nur JPEG erlaubt.'
    end

    # “Echtes JPEG” prüfen: Magic bytes FF D8 ... FF D9 (Ende optional prüfen)
    io = file.tempfile
    io.rewind
    head = io.read(2)
    return render_error(message: 'Datei ist kein JPEG.') unless head&.bytes == [0xFF, 0xD8]
    io.rewind

    username = User.current.login.to_s
    safe = username.gsub(/[^a-zA-Z0-9_.-]/, '_') # damit keine Sonderzeichen/Traversal passieren
    dest_dir = SHARE_ROOT
    dest_path = File.join(dest_dir, "#{safe}.jpeg")

    # atomisch schreiben: erst temp, dann rename
    tmp_path = File.join(dest_dir, ".#{safe}.jpeg.uploading-#{Process.pid}-#{SecureRandom.hex(6)}")

    begin
      FileUtils.mkdir_p(dest_dir)

      File.open(tmp_path, 'wb', 0o660) do |out|
        IO.copy_stream(io, out)
        out.fsync rescue nil
      end

      File.rename(tmp_path, dest_path)  # überschreibt auf Linux i.d.R. atomisch, auf CIFS meist ok
    rescue => e
      FileUtils.rm_f(tmp_path) rescue nil
      return render_error message: "Speichern fehlgeschlagen: #{e.class}: #{e.message}"
    end

    flash[:notice] = "Gespeichert als #{safe}.jpeg"
    redirect_to action: :new
  end

  private

  def authorize(ctrl = params[:controller], action = params[:action], global = false)
    allowed = User.current.allowed_to?(:upload_own_jpeg, nil, global: true)
    render_403 unless allowed
  end
end

