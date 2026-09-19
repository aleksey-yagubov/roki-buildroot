################################################################################
#
# python-st7789-roki
#
################################################################################

PYTHON_ST7789_ROKI_VERSION = 1.0.1
PYTHON_ST7789_ROKI_SOURCE = st7789-$(PYTHON_ST7789_ROKI_VERSION).tar.gz
PYTHON_ST7789_ROKI_SITE = https://files.pythonhosted.org/packages/source/s/st7789
PYTHON_ST7789_ROKI_LICENSE = MIT
PYTHON_ST7789_ROKI_LICENSE_FILES = LICENSE

define PYTHON_ST7789_ROKI_INSTALL_TARGET_CMDS
	$(INSTALL) -d $(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/site-packages/st7789
	$(INSTALL) -m 0644 $(@D)/st7789/*.py \
		$(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/site-packages/st7789/
endef

$(eval $(generic-package))
