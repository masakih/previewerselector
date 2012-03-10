
PRODUCT_NAME=ImagePreviewer
PRODUCT_EXTENSION=plugin
BUILD_PATH=./build
DEPLOYMENT=Release
APP_BUNDLE=$(PRODUCT_NAME).$(PRODUCT_EXTENSION)
APP=$(BUILD_PATH)/$(DEPLOYMENT)/$(APP_BUNDLE)
APP_NAME=$(BUILD_PATH)/$(DEPLOYMENT)/$(PRODUCT_NAME)
INFO_PLIST=Info.plist

PACKAGE_NAME=PreviewerSelector


all:
	@echo do  nothig.
	@echo use target tagging 

tagging:
	@echo "Tagging the $(VERSION) (x) release of PreviewerSelector project."
	VER=`grep -A1 'CFBundleVersion' Info.plist | tail -1 | tr -d '\t</string>'`;    \
	echo svn copy $(HEAD) $(TAGS_DIR)/release-$${VER}

Localizable:
	genstrings -o English.lproj $^
	(cd English.lproj; ${MAKE} $@;)
	genstrings -o Japanese.lproj $^
	(cd Japanese.lproj; ${MAKE} $@;)

checkLocalizable:
	(cd English.lproj; ${MAKE} $@;)
	(cd Japanese.lproj; ${MAKE} $@;)
release:
	xcodebuild -configuration $(DEPLOYMENT)

package: release
	VER=`grep -A1 'CFBundleVersion' Info.plist | tail -1 | tr -d '\t</string>'`;    \
	ditto -ck -rsrc --keepParent $(APP) $(BUILD_PATH)/$(DEPLOYMENT)/$(PACKAGE_NAME)-$${VER}.zip
