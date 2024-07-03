# modules/dev/python.nix --- https://godotengine.org/
#
# Python's ecosystem repulses me. The list of environment "managers" exhausts
# me. The Py2->3 transition make trainwrecks jealous. But SciPy, NumPy, iPython
# and Jupyter can have my babies. Every single one.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let devCfg = config.modules.dev;
    cfg = devCfg.python;
in {
  options.modules.dev.python = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt devCfg.xdg.enable;
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = with pkgs; [
        python37
        python37Packages.pip
        python37Packages.ipython
        python37Packages.black
        python37Packages.setuptools
        python37Packages.pylint
        python37Packages.poetry
      ];

      environment.shellAliases = {
        py     = "python";
        py2    = "python2";
        py3    = "python3";
        po     = "poetry";
        ipy    = "ipython --no-banner";
        ipylab = "ipython --pylab=qt5 --no-banner";
      };
    })

    (mkIf cfg.xdg.enable {
      environment.variables = {
        # Internal
        PYTHONPYCACHEPREFIX = "$XDG_CACHE_HOME/python";
        PYTHONSTARTUP = "$XDG_CONFIG_HOME/python/pythonrc";
        PYTHONUSERBASE = "$XDG_DATA_HOME/python";
        PYTHON_EGG_CACHE = "$XDG_CACHE_HOME/python-eggs";
        PYTHONHISTFILE = "$XDG_DATA_HOME/python/python_history"; # default value as of >=3.4

        # Tools
        IPYTHONDIR = "$XDG_CONFIG_HOME/ipython";
        JUPYTER_CONFIG_DIR = "$XDG_CONFIG_HOME/jupyter";
        PIP_CONFIG_FILE = "$XDG_CONFIG_HOME/pip/pip.conf";
        PIP_LOG_FILE = "$XDG_STATE_HOME/pip/log";
        PYLINTHOME = "$XDG_DATA_HOME/pylint";
        PYLINTRC = "$XDG_CONFIG_HOME/pylint/pylintrc";
        WORKON_HOME = "$XDG_DATA_HOME/virtualenvs";
      };
    })
  ];
}
