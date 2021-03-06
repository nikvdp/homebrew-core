class Neko < Formula
  desc "High-level, dynamically typed programming language"
  homepage "https://nekovm.org/"
  url "https://github.com/HaxeFoundation/neko/archive/v2-2-0/neko-2.2.0.tar.gz"
  sha256 "cf101ca05db6cb673504efe217d8ed7ab5638f30e12c5e3095f06fa0d43f64e3"
  revision 4
  head "https://github.com/HaxeFoundation/neko.git"

  bottle do
    sha256 "0b69afaf539f85ccdda6d4e84797f02dd3211339103ef788ec85b69fddc35369" => :high_sierra
    sha256 "190e61cf6002dcc4e3dbb8c3d807948dcb359456aebad490bc37986b9cc1b6e1" => :sierra
    sha256 "a8aa2f266cdf8f84a18369ca79a59230c89aaa39ff4c6043b42e26d7f0150573" => :el_capitan
    sha256 "ccf803ac93ad449b5c1574a23dedea9cb81255a341097cd60f25bc947d34227b" => :x86_64_linux
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "mbedtls"
  depends_on "bdw-gc"
  depends_on "pcre"
  depends_on "openssl"
  unless OS.mac?
    depends_on "apr"
    depends_on "apr-util"
    depends_on "httpd"
    # On mac, neko uses carbon. On Linux it uses gtk2
    depends_on "gtk+"
    depends_on "pango"
    depends_on "sqlite"
  end

  def install
    # Reduce memory usage below 4 GB for Circle CI.
    ENV["MAKEFLAGS"] = "-j1" if ENV["CIRCLECI"]

    args = std_cmake_args
    unless OS.mac?
      args << "-DAPR_LIBRARY=#{Formula["apr"].libexec}/lib"
      args << "-DAPR_INCLUDE_DIR=#{Formula["apr"].libexec}/include/apr-1"
      args << "-DAPRUTIL_LIBRARY=#{Formula["apr-util"].libexec}/lib"
      args << "-DAPRUTIL_INCLUDE_DIR=#{Formula["apr-util"].libexec}/include/apr-1"
    end

    # Let cmake download its own copy of MariaDBConnector during build and statically link it.
    # It is because there is no easy way to define we just need any one of mariadb, mariadb-connector-c,
    # mysql, and mysql-connector-c.
    system "cmake", ".", "-G", "Ninja", "-DSTATIC_DEPS=MariaDBConnector",
           "-DRELOCATABLE=OFF", "-DRUN_LDCONFIG=OFF", *args
    system "ninja", "install"
  end

  def caveats
    s = ""
    if HOMEBREW_PREFIX.to_s != "/usr/local"
      s << <<~EOS
        You must add the following line to your .bashrc or equivalent:
          export NEKOPATH="#{HOMEBREW_PREFIX}/lib/neko"
      EOS
    end
    s
  end

  test do
    ENV["NEKOPATH"] = "#{HOMEBREW_PREFIX}/lib/neko"
    system "#{bin}/neko", "-version"
  end
end
