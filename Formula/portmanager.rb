class Portmanager < Formula
  desc "Localhost Control Plane - Central port allocation for local development"
  homepage "https://github.com/bruchmann-tec/portmanager"
  version "0.1.0"
  license "MIT"


  url "https://github.com/conradBruchmann/PortManager/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "3077ba1a9871f5e2369fdb823afcebebb69824c72230958c710ec8920a449a94"


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
