class PythonAT27 < Formula
  desc "Interpreted, interactive, object-oriented programming language"
  homepage "https://www.python.org/"
  url "https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz"
  sha256 "da3080e3b488f648a3d7a4560ddee895284c3380b11d6de75edb986526b9a814"
  license "Python-2.0"
  revision 5

  livecheck do
    url "https://www.python.org/ftp/python/"
    regex(%r{href=.*?v?(2\.7(?:\.\d+)*)/?["' >]}i)
  end

  bottle do
    root_url "https://github.com/lithammer/homebrew-deadsnakes/releases/download/python@2.7-2.7.18_4"
    sha256 "21115c7dc44d5695494bc69082769cf6fdee35a7c79289c7aa7dc2bccaa48afd" => :big_sur
    sha256 "1593346ce815b0194eda7615fa4b18688e0e183eff8fc094ff43624ce333123d" => :catalina
  end

  # setuptools remembers the build flags python is built with and uses them to
  # build packages later. Xcode-only systems need different flags.
  pour_bottle? do
    on_macos do
      reason <<~EOS
        The bottle needs the Apple Command Line Tools to be installed.
          You can install them, if desired, with:
            xcode-select --install
      EOS
      satisfy { MacOS::CLT.installed? }
    end
  end

  keg_only :versioned_formula

  depends_on "pkg-config" => :build
  depends_on "gdbm"
  depends_on "openssl@1.1"
  depends_on "readline"
  depends_on "sqlite"
  depends_on "xz"

  uses_from_macos "bzip2"
  uses_from_macos "libffi"
  uses_from_macos "ncurses"
  uses_from_macos "unzip"
  uses_from_macos "zlib"

  skip_clean "bin/pip2", "bin/pip-2.6"
  skip_clean "bin/easy_install2", "bin/easy_install-2.6"

  link_overwrite "bin/2to3"
  link_overwrite "bin/idle2"
  link_overwrite "bin/pip2"
  link_overwrite "bin/pydoc2"
  link_overwrite "bin/python2"
  link_overwrite "bin/python-config2"
  link_overwrite "bin/wheel2"
  link_overwrite "share/man/man1/python2.1"
  link_overwrite "lib/pkgconfig/python2.pc"
  link_overwrite "lib/pkgconfig/python2-embed.pc"
  link_overwrite "Frameworks/Python.framework/Headers"
  link_overwrite "Frameworks/Python.framework/Python"
  link_overwrite "Frameworks/Python.framework/Resources"
  link_overwrite "Frameworks/Python.framework/Versions/Current"

  resource "setuptools" do
    url "https://files.pythonhosted.org/packages/b0/f3/44da7482ac6da3f36f68e253cb04de37365b3dba9036a3c70773b778b485/setuptools-44.0.0.zip"
    sha256 "e5baf7723e5bb8382fc146e33032b241efc63314211a3a120aaa55d62d2bb008"
  end

  resource "pip" do
    url "https://files.pythonhosted.org/packages/cb/5f/ae1eb8bda1cde4952bd12e468ab8a254c345a0189402bf1421457577f4f3/pip-20.3.1.tar.gz"
    sha256 "43f7d3811f05db95809d39515a5111dd05994965d870178a4fe10d5482f9d2e2"
  end

  resource "wheel" do
    url "https://files.pythonhosted.org/packages/d4/cf/732e05dce1e37b63d54d1836160b6e24fb36eeff2313e93315ad047c7d90/wheel-0.36.1.tar.gz"
    sha256 "aaef9b8c36db72f8bf7f1e54f85f875c4d466819940863ca0b3f3f77f0a1646f"
  end

  def lib_cellar
    on_macos do
      return prefix/"Frameworks/Python.framework/Versions/#{version.major_minor}/lib/python#{version.major_minor}"
    end
    on_linux do
      return prefix/"lib/python#{version.major_minor}"
    end
  end

  def site_packages_cellar
    lib_cellar/"site-packages"
  end

  # The HOMEBREW_PREFIX location of site-packages.
  def site_packages
    HOMEBREW_PREFIX/"lib/python#{version.major_minor}/site-packages"
  end

  def install
    # Unset these so that installing pip and setuptools puts them where we want
    # and not into some other Python the user has installed.
    ENV["PYTHONHOME"] = nil
    ENV["PYTHONPATH"] = nil

    args = %W[
      --prefix=#{prefix}
      --enable-ipv6
      --datarootdir=#{share}
      --datadir=#{share}
    ]

    on_macos do
      args << "--enable-framework=#{frameworks}"
    end
    on_linux do
      args << "--enable-shared"
      # Required for the _ctypes module
      # see https://github.com/Linuxbrew/homebrew-core/pull/1007#issuecomment-252421573
      args << "--with-system-ffi"
    end

    cflags   = ["-I#{HOMEBREW_PREFIX}/include"]
    ldflags  = ["-L#{HOMEBREW_PREFIX}/lib"]
    cppflags = ["-I#{HOMEBREW_PREFIX}/include"]

    if MacOS.sdk_path_if_needed
      # Help Python's build system (setuptools/pip) to build things on SDK-based systems
      # The setup.py looks at "-isysroot" to get the sysroot (and not at --sysroot)
      cflags  << "-isysroot #{MacOS.sdk_path}" << "-I#{MacOS.sdk_path}/usr/include"
      ldflags << "-isysroot #{MacOS.sdk_path}"
      # For the Xlib.h, Python needs this header dir with the system Tk
      # Yep, this needs the absolute path where zlib needed a path relative
      # to the SDK.
      cflags << "-I#{MacOS.sdk_path}/System/Library/Frameworks/Tk.framework/Versions/8.5/Headers"
      # Fix the following error:
      # /Library/Developer/CommandLineTools/SDKs/MacOSX10.15.sdk/System/Library/Frameworks/Tk.framework/Versions/8.5/
      # Headers/tk.h:31:3: error: Tk 8.5 must be compiled with tcl.h from Tcl 8.5
      cflags << "-I#{MacOS.sdk_path}/System/Library/Frameworks/Tcl.framework/Versions/8.5/Headers"
    end
    # Avoid linking to libgcc https://mail.python.org/pipermail/python-dev/2012-February/116205.html
    args << "MACOSX_DEPLOYMENT_TARGET=#{MacOS.version.to_f}"

    # We want our readline! This is just to outsmart the detection code,
    # superenv makes cc always find includes/libs!
    inreplace "setup.py",
      "do_readline = self.compiler.find_library_file(lib_dirs, 'readline')",
      "do_readline = '#{Formula["readline"].opt_lib}/libhistory.dylib'"

    inreplace "setup.py" do |s|
      s.gsub! "sqlite_setup_debug = False", "sqlite_setup_debug = True"
      s.gsub! "for d_ in inc_dirs + sqlite_inc_paths:",
              "for d_ in ['#{Formula["sqlite"].opt_include}']:"
      s.gsub! "/usr/local/ssl", Formula["openssl@1.1"].opt_prefix
      # Allow sqlite3 module to load extensions:
      # https://docs.python.org/library/sqlite3.html#f1
      s.gsub! 'sqlite_defines.append(("SQLITE_OMIT_LOAD_EXTENSION", "1"))', ""
    end

    # Allow python modules to use ctypes.find_library to find homebrew's stuff
    # even if homebrew is not a /usr/local/lib. Try this with:
    # `brew install enchant && pip install pyenchant`
    inreplace "./Lib/ctypes/macholib/dyld.py" do |f|
      f.gsub! "DEFAULT_LIBRARY_FALLBACK = [", "DEFAULT_LIBRARY_FALLBACK = [ '#{HOMEBREW_PREFIX}/lib',"
      f.gsub! "DEFAULT_FRAMEWORK_FALLBACK = [", "DEFAULT_FRAMEWORK_FALLBACK = [ '#{HOMEBREW_PREFIX}/Frameworks',"
    end

    args << "CFLAGS=#{cflags.join(" ")}" unless cflags.empty?
    args << "LDFLAGS=#{ldflags.join(" ")}" unless ldflags.empty?
    args << "CPPFLAGS=#{cppflags.join(" ")}" unless cppflags.empty?

    system "./configure", *args
    system "make"

    ENV.deparallelize do
      # Tell Python not to install into /Applications (default for framework builds)
      system "make", "install", "PYTHONAPPSDIR=#{prefix}"
      on_macos do
        system "make", "frameworkinstallextras", "PYTHONAPPSDIR=#{pkgshare}"
      end
    end

    # Any .app get a " 2" attached, so it does not conflict with python 3.x.
    Dir.glob("#{prefix}/*.app") { |app| mv app, app.sub(/\.app$/, " 2.app") }

    on_macos do
      # Prevent third-party packages from building against fragile Cellar paths
      inreplace [lib_cellar/"_sysconfigdata.py",
                 lib_cellar/"config/Makefile",
                 frameworks/"Python.framework/Versions/Current/lib/pkgconfig/python-2.7.pc"],
                prefix, opt_prefix

      # Fixes setting Python build flags for certain software
      # See: https://github.com/Homebrew/homebrew/pull/20182
      # https://bugs.python.org/issue3588
      inreplace lib_cellar/"config/Makefile" do |s|
        s.change_make_var! "LINKFORSHARED",
          "-u _PyMac_Error $(PYTHONFRAMEWORKINSTALLDIR)/Versions/$(VERSION)/$(PYTHONFRAMEWORK)"
      end
    end

    # Symlink the pkgconfig files into HOMEBREW_PREFIX so they're accessible.
    (lib/"pkgconfig").install_symlink Dir["#{frameworks}/Python.framework/Versions/#{version.major_minor}/lib/pkgconfig/*"]

    # Remove the site-packages that Python created in its Cellar.
    site_packages_cellar.rmtree

    %w[setuptools pip wheel].each do |r|
      (libexec/r).install resource(r)
    end

    # Remove wheel test data.
    # It's for people editing wheel and contains binaries which fail `brew linkage`.
    rm libexec/"wheel/tox.ini"
    rm_r libexec/"wheel/tests"

    # Install unversioned symlinks in libexec/bin.
    {
      "idle"          => "idle2",
      "pydoc"         => "pydoc2",
      "python"        => "python2",
      "python-config" => "python2-config",
    }.each do |unversioned_name, versioned_name|
      (libexec/"bin").install_symlink (bin/versioned_name).realpath => unversioned_name
    end
  end

  def post_install
    ENV.delete "PYTHONPATH"

    # Fix up the site-packages so that user-installed Python software survives
    # minor updates, such as going from 2.7.0 to 2.7.1:

    # Create a site-packages in HOMEBREW_PREFIX/lib/python#{version.major_minor}/site-packages
    site_packages.mkpath

    # Symlink the prefix site-packages into the cellar.
    site_packages_cellar.unlink if site_packages_cellar.exist?
    site_packages_cellar.parent.install_symlink site_packages

    # Write our sitecustomize.py
    rm_rf Dir["#{site_packages}/sitecustomize.py[co]"]
    (site_packages/"sitecustomize.py").atomic_write(sitecustomize)

    # Remove old setuptools installations that may still fly around and be
    # listed in the easy_install.pth. This can break setuptools build with
    # zipimport.ZipImportError: bad local file header
    # setuptools-0.9.8-py3.3.egg
    rm_rf Dir["#{site_packages}/setuptools*"]
    rm_rf Dir["#{site_packages}/distribute*"]
    rm_rf Dir["#{site_packages}/pip[-_.][0-9]*", "#{site_packages}/pip"]
    rm_rf Dir["#{site_packages}/wheel*"]

    system bin/"python2", "-m", "ensurepip"

    # Get set of ensurepip-installed files for later cleanup
    ensurepip_files = Set.new(Dir["#{site_packages}/setuptools-*"]) +
                      Set.new(Dir["#{site_packages}/pip-*"]) +
                      Set.new(Dir["#{site_packages}/wheel-*"])

    # Remove Homebrew distutils.cfg if it exists, since it prevents the subsequent
    # pip install command from succeeding (it will be recreated afterwards anyways)
    rm_f lib_cellar/"distutils/distutils.cfg"

    # Install desired versions of setuptools, pip, wheel using the version of
    # pip bootstrapped by ensurepip
    system bin/"python2", "-m", "pip", "install", "-v", "--global-option=--no-user-cfg",
           "--install-option=--force",
           "--install-option=--single-version-externally-managed",
           "--install-option=--record=installed.txt",
           "--upgrade",
           "--target=#{site_packages}",
           libexec/"setuptools",
           libexec/"pip",
           libexec/"wheel"

    # Get set of files installed via pip install
    pip_files = Set.new(Dir["#{site_packages}/setuptools-*"]) +
                Set.new(Dir["#{site_packages}/pip-*"]) +
                Set.new(Dir["#{site_packages}/wheel-*"])

    # Clean up the bootstrapped copy of setuptools/pip provided by ensurepip.
    # Also consider the corner case where our desired version of tools is
    # the same as those provisioned via ensurepip. In this case, don't clean
    # up, or else we'll have no working setuptools, pip, wheel
    if pip_files != ensurepip_files
      ensurepip_files.each do |dir|
        rm_rf dir
      end
    end

    # pip install with --target flag will just place the bin folder into the
    # target, so move its contents into the appropriate location
    mv (site_packages/"bin").children, bin
    rmdir site_packages/"bin"

    rm_rf [bin/"pip", bin/"easy_install"]
    mv bin/"wheel", bin/"wheel2"

    # Install unversioned symlinks in libexec/bin.
    {
      "easy_install" => "easy_install-#{version.major_minor}",
      "pip"          => "pip2",
      "wheel"        => "wheel2",
    }.each do |unversioned_name, versioned_name|
      (libexec/"bin").install_symlink (bin/versioned_name).realpath => unversioned_name
    end

    # post_install happens after link
    %W[python python2 python#{version.major_minor}].each do |e|
      (HOMEBREW_PREFIX/"bin").install_symlink bin/e
    end

    # Help distutils find brewed stuff when building extensions
    include_dirs = [HOMEBREW_PREFIX/"include", Formula["openssl@1.1"].opt_include,
                    Formula["sqlite"].opt_include]
    library_dirs = [HOMEBREW_PREFIX/"lib", Formula["openssl@1.1"].opt_lib,
                    Formula["sqlite"].opt_lib]

    cfg = lib_cellar/"distutils/distutils.cfg"

    cfg.atomic_write <<~EOS
      [install]
      prefix=#{HOMEBREW_PREFIX}
      [build_ext]
      include_dirs=#{include_dirs.join ":"}
      library_dirs=#{library_dirs.join ":"}
    EOS
  end

  def sitecustomize
    <<~EOS
      # This file is created by Homebrew and is executed on each python startup.
      # Don't print from here, or else python command line scripts may fail!
      # <https://docs.brew.sh/Homebrew-and-Python>
      import re
      import os
      import sys
      if sys.version_info[0] != 2:
          # This can only happen if the user has set the PYTHONPATH for 3.x and run Python 2.x or vice versa.
          # Every Python looks at the PYTHONPATH variable and we can't fix it here in sitecustomize.py,
          # because the PYTHONPATH is evaluated after the sitecustomize.py. Many modules (e.g. PyQt4) are
          # built only for a specific version of Python and will fail with cryptic error messages.
          # In the end this means: Don't set the PYTHONPATH permanently if you use different Python versions.
          exit('Your PYTHONPATH points to a site-packages dir for Python 2.x but you are running Python ' +
               str(sys.version_info[0]) + '.x!\\n     PYTHONPATH is currently: "' + str(os.environ['PYTHONPATH']) + '"\\n' +
               '     You should `unset PYTHONPATH` to fix this.')
      # Only do this for a brewed python:
      if os.path.realpath(sys.executable).startswith('#{rack}'):
          # Shuffle /Library site-packages to the end of sys.path
          library_site = '/Library/Python/#{version.major_minor}/site-packages'
          library_packages = [p for p in sys.path if p.startswith(library_site)]
          sys.path = [p for p in sys.path if not p.startswith(library_site)]
          # .pth files have already been processed so don't use addsitedir
          sys.path.extend(library_packages)
          # the Cellar site-packages is a symlink to the HOMEBREW_PREFIX
          # site_packages; prefer the shorter paths
          long_prefix = re.compile(r'#{rack}/[0-9\._abrc]+/Frameworks/Python\.framework/Versions/#{version.major_minor}/lib/python#{version.major_minor}/site-packages')
          sys.path = [long_prefix.sub('#{HOMEBREW_PREFIX/"lib/python#{version.major_minor}/site-packages"}', p) for p in sys.path]
          # Set the sys.executable to use the opt_prefix. Only do this if PYTHONEXECUTABLE is not
          # explicitly set and we are not in a virtualenv:
          if 'PYTHONEXECUTABLE' not in os.environ and sys.prefix == sys.base_prefix:
              sys.executable = '#{opt_bin}/python#{version.major_minor}'
    EOS
  end

  def caveats
    <<~EOS
      Python has been installed as
        #{opt_bin}/python2

      Unversioned symlinks `python`, `python-config`, `pip` etc. pointing to
      `python2`, `python2-config`, `pip2` etc., respectively, have been installed into
        #{opt_libexec}/bin

      You can install Python packages with
        #{opt_bin}/pip2 install <package>
      They will install into the site-package directory
        #{HOMEBREW_PREFIX/"lib/python#{version.major_minor}/site-packages"}

      See: https://docs.brew.sh/Homebrew-and-Python
    EOS
  end

  test do
    # Check if sqlite is ok, because we build with --enable-loadable-sqlite-extensions
    # and it can occur that building sqlite silently fails if OSX's sqlite is used.
    system "#{bin}/python#{version.major_minor}", "-c", "import sqlite3"

    # Check if some other modules import. Then the linked libs are working.
    system "#{bin}/python#{version.major_minor}", "-c", "import gdbm"
    system "#{bin}/python#{version.major_minor}", "-c", "import hashlib"
    system "#{bin}/python#{version.major_minor}", "-c", "import ssl"
    system "#{bin}/python#{version.major_minor}", "-c", "import zlib"
    on_macos do
      # Temporary failure on macOS 11.1 due to https://bugs.python.org/issue42480
      # Reenable unconditionnaly once Apple fixes the Tcl/Tk issue
      system "#{bin}/python#{version.major_minor}", "-c", "import Tkinter; root = Tkinter.Tk()" if MacOS.full_version < "11.1"
    end

    system bin/"pip2", "list", "--format=columns"
  end
end
