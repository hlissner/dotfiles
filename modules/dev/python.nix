# modules/dev/python.nix --- https://godotengine.org/
#
# Python's ecosystem repulses me. The list of environment "managers" exhausts
# me. The Py2->3 transition make trainwrecks jealous. But SciPy, NumPy, iPython
# and Jupyter can have my babies. Every single one.

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.dev.python = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.dev.python.enable {
    my = {
      packages = with pkgs; [
        python37
        python37Packages.pip
        python37Packages.ipython
        python37Packages.black
        python37Packages.setuptools
        python37Packages.pylint
        python37Packages.poetry
      ];

      env.IPYTHONDIR      = "$XDG_CONFIG_HOME/ipython";
      env.PIP_CONFIG_FILE = "$XDG_CONFIG_HOME/pip/pip.conf";
      env.PIP_LOG_FILE    = "$XDG_DATA_HOME/pip/log";
      env.PYLINTHOME      = "$XDG_DATA_HOME/pylint";
      env.PYLINTRC        = "$XDG_CONFIG_HOME/pylint/pylintrc";
      env.PYTHONSTARTUP   = "$XDG_CONFIG_HOME/python/pythonrc";
      env.PYTHON_EGG_CACHE = "$XDG_CACHE_HOME/python-eggs";
      env.JUPYTER_CONFIG_DIR = "$XDG_CONFIG_HOME/jupyter";

      zsh.rc = lib.readFile <config/python/aliases.zsh>;

      alias.py  = "python";
      alias.py2 = "python2";
      alias.py3 = "python3";
      alias.po  = "poetry";
      alias.ipy = "ipython --no-banner";
      alias.ipylab = "ipython --pylab=qt5 --no-banner";
    };
  };
}
