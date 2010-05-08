#     PREREQ_PM => { Test::More=>q[0], File::Path=>q[0], Module::Build=>q[0.28], File::Copy=>q[0], IO::File=>q[0], File::Spec=>q[0], Gtk2::MozEmbed=>q[0], File::BaseDir=>q[0.03], Gtk2::GladeXML=>q[0], File::DesktopEntry=>q[0.03], Encode=>q[0], POSIX=>q[0], Gtk2=>q[1.040], File::MimeInfo=>q[0.12] }

all : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1
realclean : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 realclean
	/usr/bin/perl -e '1 while unlink $$ARGV[0]' Makefile
distclean : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 distclean
	/usr/bin/perl -e '1 while unlink $$ARGV[0]' Makefile


force_do_it :
	@ true
build : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 build
clean : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 clean
code : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 code
config_data : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 config_data
diff : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 diff
dist : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 dist
distcheck : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 distcheck
distdir : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 distdir
distmeta : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 distmeta
distsign : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 distsign
disttest : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 disttest
docs : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 docs
fakeinstall : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 fakeinstall
help : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 help
html : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 html
install : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 install
manifest : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 manifest
manpages : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 manpages
messages : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 messages
pardist : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 pardist
postinstall : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 postinstall
ppd : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 ppd
ppmdist : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 ppmdist
prereq_data : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 prereq_data
prereq_report : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 prereq_report
pure_install : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 pure_install
retest : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 retest
skipcheck : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 skipcheck
static : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 static
test : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 test
test_data : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 test_data
testall : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 testall
testcover : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 testcover
testdb : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 testdb
testflow : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 testflow
testpod : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 testpod
testpodcoverage : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 testpodcoverage
versioninstall : force_do_it
	/usr/bin/perl Build --makefile_env_macros 1 versioninstall

.EXPORT : INSTALLARCHLIB INSTALLSCRIPT INSTALLVENDORSCRIPT INSTALLSITEMAN1DIR INSTALLSITESCRIPT DESTDIR VERBINST INSTALLSITEARCH INSTALLSITEBIN INSTALLVENDORMAN3DIR INSTALLVENDORBIN UNINST POLLUTE INSTALLVENDORLIB INSTALLPRIVLIB INSTALLMAN3DIR INC INSTALLSITELIB INSTALLVENDORMAN1DIR PREFIX INSTALLDIRS INSTALLVENDORARCH TEST_VERBOSE INSTALLMAN1DIR INSTALLBIN INSTALL_BASE INSTALLSITEMAN3DIR

