class Arpack < Formula
  desc "Routines to solve large scale eigenvalue problems"
  homepage "https://github.com/opencollab/arpack-ng"
  url "https://github.com/opencollab/arpack-ng/archive/3.6.0.tar.gz"
  sha256 "3c88e74cc10bba81dc2c72c4f5fff38a800beebaa0b4c64d321c28c9203b37ea"
  head "https://github.com/opencollab/arpack-ng.git"

  bottle do
    sha256 "3a9e865b2c3f78e307d5652a4ee8a6c57671c09f9099f870711b1609ccfa362e" => :high_sierra
    sha256 "d9c6fb5dde09005ce6ac633d38c781fc5853696b4c3bbdc32631c106ad9c3db8" => :sierra
    sha256 "f55010de5857a69507cde6348a6b4e407cbc0829c853b9f6d22ec4f4003d3548" => :el_capitan
    sha256 "3f28fd1d62524c334a3b067abf890a910f9c92e4b8155303ae4a3d4ba47a5aff" => :x86_64_linux
  end

  option "with-mpi", "Enable parallel support"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  depends_on "gcc" # for gfortran
  depends_on "veclibfort" if build.without?("openblas") && OS.mac?
  depends_on "open-mpi" if build.with? "mpi"
  depends_on "openblas" unless OS.mac?

  def install
    args = %W[ --disable-dependency-tracking
               --prefix=#{libexec} ]
    if build.with? "openblas"
      args << "--with-blas=-L#{Formula["openblas"].opt_lib} -lopenblas"
    elsif build.with? "veclibfort"
      args << "--with-blas=-L#{Formula["veclibfort"].opt_lib}\ -lvecLibFort"
    else
      args << "--with-blas=-lblas -llapack"
    end

    args << "F77=mpif77" << "--enable-mpi" if build.with? "mpi"

    system "./bootstrap"
    system "./configure", *args
    system "make"
    system "make", "install"

    lib.install_symlink Dir["#{libexec}/lib/*"].select { |f| File.file?(f) }
    (lib/"pkgconfig").install_symlink Dir["#{libexec}/lib/pkgconfig/*"]
    pkgshare.install "TESTS/testA.mtx", "TESTS/dnsimp.f",
                     "TESTS/mmio.f", "TESTS/debug.h"

    if build.with? "mpi"
      (libexec/"bin").install (buildpath/"PARPACK/EXAMPLES/MPI").children
    end
  end

  test do
    system "gfortran", "-o", "test", pkgshare/"dnsimp.f", pkgshare/"mmio.f",
                       "-L#{lib}", "-larpack",
                       *("-lvecLibFort" if OS.mac?),
                       *("-lopenblas" unless OS.mac?)

    cp_r pkgshare/"testA.mtx", testpath
    assert_match "reached", shell_output("./test")

    if build.with? "mpi"
      cp_r (libexec/"bin").children, testpath
      %w[pcndrv1 pdndrv1 pdndrv3 pdsdrv1
         psndrv1 psndrv3 pssdrv1 pzndrv1].each do |slv|
        system "mpirun", "-np", "4", slv
      end
    end
  end
end
