
INFO_PLIST=../Info.plist
LOCALIZED_INFO_PLIST=InfoPlist.strings

updateVersion:
	cp $(LOCALIZED_INFO_PLIST) $(LOCALIZED_INFO_PLIST).bak;	\
	REV=`grep -A1 'CFBundleVersion' $(INFO_PLIST) | sed -n -e 's:.*<string>\(.*\)</string>.*:\1:p'`;\
	sed -e "s/%%%%VERSION%%%%/$${REV}/" $(LOCALIZED_INFO_PLIST) > $(LOCALIZED_INFO_PLIST).r ;	\
	mv -f $(LOCALIZED_INFO_PLIST).r $(LOCALIZED_INFO_PLIST) ;	\

restorInfoPlist:
	if [ -f $(LOCALIZED_INFO_PLIST).bak ] ; then cp -f $(LOCALIZED_INFO_PLIST).bak $(LOCALIZED_INFO_PLIST) ; fi

