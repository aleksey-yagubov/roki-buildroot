################################################################################
#
# python-starkit
#
################################################################################

PYTHON_STARKIT_VERSION = 0.0.3
PYTHON_STARKIT_SITE = https://files.pythonhosted.org/packages/source/s/starkit
PYTHON_STARKIT_SOURCE = starkit-$(PYTHON_STARKIT_VERSION).tar.gz
PYTHON_STARKIT_LICENSE = MIT
PYTHON_STARKIT_LICENSE_FILES = LICENSE.md
PYTHON_STARKIT_SETUP_TYPE = setuptools

# Upstream 0.0.3 calls setup() twice. The first call builds the extension;
# the second produces a conflicting empty wheel with modern PEP 517 tooling.
define PYTHON_STARKIT_FIX_UPSTREAM_SETUP
	$(SED) '9,$$d' $(@D)/setup.py
endef
PYTHON_STARKIT_POST_EXTRACT_HOOKS += PYTHON_STARKIT_FIX_UPSTREAM_SETUP

$(eval $(python-package))
