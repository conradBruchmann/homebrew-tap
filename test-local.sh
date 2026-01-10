#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TAP_DIR="$SCRIPT_DIR"

echo "=== PortManager Homebrew Local Test ==="
echo ""

# Step 1: Stop existing daemon if running
echo "1. Stopping existing daemon..."
launchctl stop com.bruchmann-tec.portmanager 2>/dev/null || true
brew services stop portmanager 2>/dev/null || true
killall portmanager-daemon 2>/dev/null || true
sleep 1

# Step 2: Create tarball with root directory
echo "2. Creating source tarball..."
TARBALL="/tmp/portmanager-source.tar.gz"
TMPDIR="/tmp/portmanager-build"
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR/portmanager-0.1.0"
cp -r "$PROJECT_ROOT/port_manager" "$TMPDIR/portmanager-0.1.0/"
cd "$TMPDIR"
tar -czf "$TARBALL" portmanager-0.1.0
rm -rf "$TMPDIR"

# Step 3: Calculate SHA256
echo "3. Calculating checksum..."
SHA256=$(shasum -a 256 "$TARBALL" | cut -d' ' -f1)
echo "   SHA256: $SHA256"

# Step 4: Update formula with correct URL and checksum
echo "4. Updating formula..."
cat > "$TAP_DIR/Formula/portmanager.rb" << EOF
class Portmanager < Formula
  desc "Localhost Control Plane - Central port allocation for local development"
  homepage "https://github.com/bruchmann-tec/portmanager"
  version "0.1.0"
  license "MIT"

  url "file://$TARBALL"
  sha256 "$SHA256"

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
EOF

# Step 4b: Commit the updated formula
echo "4b. Committing formula update..."
cd "$TAP_DIR"
git add Formula/portmanager.rb
git commit -m "Update checksum for local testing" 2>/dev/null || true

# Step 5: Uninstall previous version if exists
echo "5. Removing previous installation..."
brew uninstall portmanager 2>/dev/null || true
brew untap bruchmann-tec/tap 2>/dev/null || true

# Step 6: Tap local repository
echo "6. Tapping local repository..."
brew tap bruchmann-tec/tap "$TAP_DIR"

# Step 7: Install
echo "7. Installing portmanager (this may take a while - compiling Rust)..."
brew install bruchmann-tec/tap/portmanager

# Step 8: Start service
echo "8. Starting service..."
brew services start portmanager
sleep 2

# Step 9: Test
echo "9. Testing..."
echo ""
echo "--- portctl list ---"
/opt/homebrew/bin/portctl list || echo "(no leases yet)"
echo ""
echo "--- Daemon status ---"
brew services list | grep portmanager
echo ""
echo "--- Dashboard check ---"
curl -s http://localhost:3030 | head -3
echo ""

echo ""
echo "=== Installation complete! ==="
echo ""
echo "Dashboard: http://localhost:3030"
echo "Try: portctl run test-service -- echo 'Hello from port \$PORT'"
