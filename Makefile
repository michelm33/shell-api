# Creation of debian package relies on 
# package dh-make
# package devscripts
# List content of a deb package: dpkg -c ../mountpilot_2.0.0_all.deb
# debuild -us -uc -b
# only debuild seem to work
# dpkg-buildpackage -A -uc should also work
#
# About end message "new-package-should-close-itp-bug": see https://www.debian.org/doc/manuals/developers-reference/pkgs.html#newpackage. 
# If package is intended to be integrated to the base debian package, it must follow the procedure described there.
#
# //////////////////////////////////////////////////////////////////////////////////////////
#
# IMPORTANT RUN MAKE ON THE DEVELOPMENT MACHINE e.g. 'riffian-dell', not the server 'riffian'
#
# //////////////////////////////////////////////////////////////////////////////////////////
#
ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
TARGET=/usr/share/man/man8/
VERSION=$(shell cat VERSION.txt)
VERSION_DEB=$(shell awk -F'.' '{ printf("%s.%s-%s" ,$$1,$$2,$$3);}' VERSION.txt)
VERSION_DEB_FOR_TARXV=$(shell awk -F'.' '{ printf("%s.%s_%s" ,$$1,$$2,$$3);}' VERSION.txt)
VERSION_DEB_FOR_ZIP=$(shell awk -F'.' '{ printf("%s.%s-%s" ,$$1,$$2,$$3);}' VERSION.txt)
PRODUCT=shell-api
PKG=$(PRODUCT)-$(VERSION_DEB)
DATE=$(shell LC_ALL=en_US.UTF-8 date --rfc-email)

PROD_REL_DIR=../release/$(PRODUCT)/
VERS_REL_DIR=$(PROD_REL_DIR)/$(PKG)

.PHONY: FORCE

.PHONY: all
all:

.PHONY: man
man: shellapi.8 man_install
	@echo 
	@echo "#################################"
	@echo "Creating MANPAGE.txt from man pages"
	@echo 
	# Run manpage.txt generation in a terminal of a preselected
	# width, because paging done by man is dependent of it
	gnome-terminal --geometry 80x50+0+0 --title="shellapi"  --wait -- bash -c 'man shellapi > MANPAGE.txt'
	#man shellapi > MANPAGE.txt
	@if which arcv >/dev/null 2>/dev/null; then av diff >/dev/null ; if [ $$? -eq 0 ] ; then av -y co MANPAGE.txt >/dev/null; fi ; fi


.PHONY: man_install
man_install: shellapi.8
	@echo 
	@echo "#################################"
	@echo "Installing man pages and building gzip for $(TARGET)/$<"
	@echo 
	@if which arcv >/dev/null 2>/dev/null; then av diff >/dev/null ; if [ $$? -eq 0 ] ; then av -y co $< >/dev/null; fi ; fi
	sudo install -g 0 -o 0 -m 0644 $< $(TARGET)
	sudo gzip -f $(TARGET)/$<

shellapi.8: required_help2man FORCE
	@echo 
	@echo "#################################"
	@echo "Creating manpage with help2man"
	@echo 
	help2man -L en_EN@euro --no-info --section 8 --name "shell-api" --help-option="--man" --output=$@ ./genapp
# --manual="System Administration Utilities"

.PHONY: required_help2man
required_help2man:
	@[  `dpkg-query -W -f='$${db:Status-Abbrev}' help2man` = "ii"  ] && echo "help2man is installed" || sudo apt install help2man


.PHONY: required_tools
required_tools:
	@[  `dpkg-query -W -f='$${db:Status-Abbrev}' zip` = "ii"  ] && echo "Zip is installed" || sudo apt install zip
	@[  `dpkg-query -W -f='$${db:Status-Abbrev}' dh-make` = "ii"  ] && echo "dh-make is installed" || sudo apt install dh-make

check_uptodate: FORCE
	cd "$(ROOT_DIR)" && av check

.PHONY: release
release: required_tools man release_no_man_internal
	@echo SUCCESS

.PHONY: release_no_man_internal
release_no_man_internal: check_uptodate create_package update_website_ftp
	@echo SUCCESS

.PHONY: pub
pub: export tag

.PHONY: tag
tag:
	@echo 
	@echo 
	@echo "REQUESTING TO TAG RELEASE WITH ARCV. CTRL-C TO ABORT."
	@echo " IF ABORTED, TYPE 'make release_tag' or 'av pub' TO RESTART"
	@echo 
	@av pub

.PHONY: export
export:
	@echo 
	@echo 
	@echo "REQUESTING TO EXPORT RELEASE TO GITHUB WITH ARCV. CTRL-C TO ABORT"
	@echo " IF ABORTED, TYPE 'make release_export' or 'av export' TO RESTART"
	@echo 
	@av export $(VERSION_DEB)

.PHONY: build_release
build_release:  required_tools  CHANGELOG.txt COPYRIGHT.txt VERSION.txt
	@echo 
	@echo "#################################"
	@echo "CLEAN UP EXISTING RELEASE FOLDER IF ANY"
	@echo 
	@echo "Cleaning up $(VERS_REL_DIR)"
	@if [ -d $(VERS_REL_DIR) ] ; then rm -rf $(VERS_REL_DIR) >/dev/null; echo "Removed former folder $(VERS_REL_DIR)"; fi 
	@# The file created is mountpilot-2.0_1.orig.tar.xz, but VERSION_DEB is 2.0-1..........
	@echo "Cleaning up $(PROD_REL_DIR)/$(PRODUCT)-$(VERSION_DEB_FOR_TARXV).orig.tar.xz"
	@rm "$(PROD_REL_DIR)/$(PRODUCT)-$(VERSION_DEB_FOR_TARXV).orig.tar.xz" 2>/dev/null || echo 
	@sleep 2
	@mkdir -p $(VERS_REL_DIR)/ 2>/dev/null 
	@echo 
	@echo "#################################"
	@echo BUILD RELEASE $(PKG)
	@rsync -a * $(VERS_REL_DIR)/ 
	@# If arcv is used, generate the REVISION.txt file
	@if which arcv >/dev/null 2>/dev/null; then arcv -n --silent check 2>/dev/null; if [ $$? -lt 200 ] ; then arcv rev > $(VERS_REL_DIR)/REVISION.txt ; arcv hash >> $(VERS_REL_DIR)/REVISION.txt ;  fi; fi
	@cm-manage-copyright.sh $(VERS_REL_DIR) .
	@cd $(VERS_REL_DIR)/
	@echo 
	@echo "#################################"
	@echo "CREATING THE RELEASE ZIP FILES"
	@#
	@cd $(PROD_REL_DIR) && zip -q -r "$(PRODUCT)_$(VERSION_DEB_FOR_ZIP).zip" ./$(PKG)
	@echo 
	@echo "#################################"
	@echo "CREATING THE DEBIAN PACKAGE"
	@# DEB_BUILD_OPTIONS=nocheck
	@cd $(VERS_REL_DIR) &&  dh_make --createorig  -c custom --copyrightfile ../COPYRIGHT.txt -e michel.mehl@slashetc.fr -i -y
	@#
	@echo "----- CREATING THE DEBIAN CHANGE LOG FILE"
	@echo -n "$(PRODUCT) " > $(VERS_REL_DIR)/debian/changelog
	@echo -n "($(VERSION_DEB))" >> $(VERS_REL_DIR)/debian/changelog
	@echo " UNRELEASED; urgency=low" >> $(VERS_REL_DIR)/debian/changelog
	@echo >> $(VERS_REL_DIR)/debian/changelog
	@echo -n "  " >> $(VERS_REL_DIR)/debian/changelog
	@cat CHANGELOG.txt|head -n1 >> $(VERS_REL_DIR)/debian/changelog
	@# INDENT IS RELEVANT BELOW !!
	@echo >> $(VERS_REL_DIR)/debian/changelog
	@echo " -- Michel Mehl <michel.mehl@slashetc.fr>  $(DATE)" >> $(VERS_REL_DIR)/debian/changelog
	@echo "" >> $(VERS_REL_DIR)/debian/changelog
	@#
	@echo "----- CREATING THE DEBIAN CONTROL FILE"
	@cp pack/debian/control $(VERS_REL_DIR)/debian/
	@#
	@echo "----- CREATING THE DEBIAN INSTALL FILES"
	@cd $(VERS_REL_DIR) && ls -1|grep -v debian|awk '{ print $$1,"/usr/bin/shell-api" }' > debian/install
	@#
	@#echo "----- DEBIAN MANPAGE FILE"
	@#cp shell-api.8 $(VERS_REL_DIR)/debian/$(PRODUCT).8
	@#echo "debian/shell-api.8" > $(VERS_REL_DIR)/debian/$(PRODUCT).manpages
	@#
	@echo "----- CLEANUP EXAMPLE FILES"
	@rm -rf $(VERS_REL_DIR)/debian/*.ex 2>/dev/null || echo  # example folders
	@rm $(VERS_REL_DIR)/debian/README.* 2>/dev/null || echo
	@#


.PHONY: create_package
create_package: build_release build_package build_package_cleanup
	@echo 
	@echo "#################################"
	@echo "FINISHED"
	@echo 

# an alias for update_website_ftp
.PHONY: package
package : create_package

.PHONY: build_package
build_package:
	@echo 
	@echo "#################################"
	@echo "BUILD PACKAGE FROM EXISTING RELEASE FILE TREE"
	@echo 
	@# -d is for ignoring  error: Unmet build dependencies: debhelper-compat (= 13)
	@cd $(VERS_REL_DIR) && debuild -ui -us -uc -b -d | grep -E ^[A-Z]: && echo || echo '!!!!!!!!!!!!!!!! FAIL !!!!!!!!!!!!!!!!'

.PHONY: build_package_cleanup
build_package_cleanup:
	@echo 
	@echo "#################################"
	@echo "CLEANING UP DEBIAN BUILD GENERATED FILES"
	@echo 
	@cd $(VERS_REL_DIR)/debian && rm -r .debhelper && rm -rf $(PRODUCT) && rm debhelper* && rm files && rm rules && echo || echo '!!!!!!!!!!!!!!!! FAIL !!!!!!!!!!!!!!!!'

.PHONY: update_website_ftp
update_website_ftp:
	@echo 
	@echo "#################################"
	@echo "UPLOADING TO FTP"
	@echo 
	@sf -F -y && echo && echo '>>>>>>>>>>>>>>> SUCCESS <<<<<<<<<<<<<<<<<<<<' ||  echo '!!!!!!!!!!!!!!!! FAIL !!!!!!!!!!!!!!!!'
	@echo 

# an alias for update_website_ftp
.PHONY: upload
upload : update_website_ftp