class Portmanager < Formula
  desc "Localhost Control Plane - Central port allocation for local development"
  homepage "https://github.com/bruchmann-tec/portmanager"
  version "0.2.0"
  license "MIT"


  url "https://github.com/conradBruchmann/PortManager/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "9ab3e005fc06da7265553f04b9b853591ebf543ccfdb697b062b82df52d27a68"


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


      Dashboard: http://localhost:7878
        (override via PM_DASHBOARD_PORT)


      Usage:
        portctl run my-service -- npm start
        portctl list
        portctl lookup my-service
    EOS
  end
end
