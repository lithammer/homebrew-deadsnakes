class PythonGdbmAT312 < Formula
  desc "Python interface to gdbm"
  homepage "https://www.python.org/"
  url "https://www.python.org/ftp/python/3.12.0/Python-3.12.0a7.tgz"
  sha256 "86d288766153193706e545cc98f73ea8ef1a9cb057608cfdecbd89190b796cf6"
  license "Python-2.0"
  head "https://github.com/python/cpython.git", branch: "main"

  livecheck do
    formula "python@3.12"
  end

  bottle do
    root_url "https://github.com/lithammer/homebrew-deadsnakes/releases/download/python-gdbm@3.12-3.12.0a6"
    sha256 cellar: :any, monterey: "6fce7506d711751b84c7ca29bcf7c3ebd6003ffc72ce523a85fa5d4fd1649341"
  end

  depends_on "gdbm"
  depends_on "python@3.12"

  def python3
    "python3.12"
  end

  def install
    cd "Modules" do
      (Pathname.pwd/"setup.py").write <<~EOS
        from setuptools import setup, Extension

        setup(name="gdbm",
              description="#{desc}",
              version="#{version}",
              ext_modules = [
                Extension("_gdbm", ["_gdbmmodule.c"],
                          include_dirs=["#{Formula["gdbm"].opt_include}"],
                          libraries=["gdbm"],
                          library_dirs=["#{Formula["gdbm"].opt_lib}"])
              ]
        )
      EOS
      system python3, *Language::Python.setup_install_args(libexec, python3),
                      "--install-lib=#{libexec}"
      rm_r libexec.glob("*.egg-info")
    end
  end

  test do
    testdb = testpath/"test.db"
    system python3, "-c", <<~EOS
      import dbm.gnu

      with dbm.gnu.open("#{testdb}", "n") as db:
        db["testkey"] = "testvalue"

      with dbm.gnu.open("#{testdb}", "r") as db:
        assert db["testkey"] == b"testvalue"
    EOS
  end
end
