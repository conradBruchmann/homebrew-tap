class Portmanager < Formula
  desc "Localhost Control Plane - Central port allocation for local development"
  homepage "https://github.com/bruchmann-tec/portmanager"
  version "0.1.0"
  license "MIT"

  url "file:///tmp/portmanager-source.tar.gz"
  sha256 "9c304e62fc95c82f2882801879611e02d97403f75b70dd8226269962efa76485"

  depends_on "rust" => :build

  def install
    cd "port_manager" do
      system "cargo", "build", "--release"
      bin.install "target/release/daemon" => "portmanager-daemon"
      bin.install "target/release/client" => "portctl"
    end

    (var/"portmanager").mkpath
  end

  def caveats
    <<~EOS
      PortManager has been installed!

      Start the daemon:
        brew services start portmanager

      Or run manually:
        portmanager-daemon

      Dashboard: http://localhost:3030

      Usage:
        portctl run my-service -- npm start
        portctl list
        portctl lookup my-service
    EOS
  end

  service do
    run [opt_bin/"portmanager-daemon"]
    keep_alive true
    log_path var/"log/portmanager.log"
    error_log_path var/"log/portmanager.error.log"
    working_dir var/"portmanager"
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/portctl --help", 2)
  end
end
