PROJECT:=Snail King
AUTHOR:=simplex
VERSION:=prealpha
API_VERSION:=3
define DESCRIPTION =
Development version of the Snail King (a.k.a. Lou Carcolh) mod.
Art by lifemare and MilleniumCount.
Code by simplex.
Concept by Symage, Lord_Battal, lifemare, MilleniumCount and simplex.
endef

FORUM_THREAD:=26065
FORUM_DOWNLOAD_ID:=1


PROJECT_lc:=$(shell echo $(PROJECT) | tr A-Z a-z | tr -d [:blank:])
SCRIPT_DIR:=scripts/$(PROJECT_lc)


IS_PERSISTENT:=1


include $(SCRIPT_DIR)/wicker/make/preamble.mk

FILES:=

THEMAIN:=$(SCRIPT_DIR)/main.lua
FILES+=$(THEMAIN)

GROUND_SCRIPTS:=modmain.lua modinfo.lua
FILES+=$(GROUND_SCRIPTS)

MISC_SCRIPTS:=$(foreach f, debugtools.lua, $(SCRIPT_DIR)/$(f))
FILES+=$(MISC_SCRIPTS)

PREFAB_SCRIPTS:=$(call WICKER_ADD_PREFABS, snailking.lua)
COMPONENT_SCRIPTS:=
STATEGRAPH_SCRIPTS:=$(call WICKER_ADD_STATEGRAPHS, SGsnailking.lua)
BRAIN_SCRIPTS:=$(call WICKER_ADD_BRAINS, snailkingbrain.lua)
FILES+=$(PREFAB_SCRIPTS) $(COMPONENT_SCRIPTS) $(STATEGRAPH_SCRIPTS) $(BRAIN_SCRIPTS)


LICENSE_FILES:=AUTHORS.txt COPYING.txt
IMAGE_FILES:=
ANIM_FILES:=anim/snailking_build.zip anim/snailking_death_build.zip

FILES+=$(LICENSE_FILES) $(IMAGE_FILES) $(ANIM_FILES)


include $(SCRIPT_DIR)/wicker/make/rules.mk
