#@HDR@	$Id$
#@HDR@		Copyright 2024 by
#@HDR@		Christopher Caldwell/Brightsands
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of Brightsands and may not be used, copied or made available
#@HDR@	to anyone, except in accordance with the license under which
#@HDR@	it is furnished.
PROJECTSDIR?=$(shell echo $(CURDIR) | sed -e 's+/projects/.*+/projects+')
include $(PROJECTSDIR)/common/Makefile.std

LOG2CFG=src/log2cfg.pl
REFDIR=$(PROJECTDIR)/ref
CFGDIR=$(PROJECTDIR)/cfg
TESTDCFG=$(CFGDIR)/testd.cfg
SCREEN=4Ml

IP_LOGS=$(addsuffix .log,$(subst $(REFDIR)/,$(CFGDIR)/,$(wildcard $(REFDIR)/*.ip)))
TR_LOGS=$(addsuffix .log,$(subst $(REFDIR)/,$(CFGDIR)/,$(wildcard $(REFDIR)/*.traceroute)))
NMAP_LOGS=$(addsuffix .log,$(subst $(REFDIR)/,$(CFGDIR)/,$(wildcard $(REFDIR)/*.nmap)))

cfg:
		@echo "LOG2CFG=$(LOG2CFG)"
		@echo "LOGS=$(LOGS)"
		@echo "TEST_SOURCES=$(TEST_SOURCES)"
		@echo "CFGDIR=$(CFGDIR)"
		@echo "TEST_RESULTS=$(TEST_RESULTS)"

.PRECIOUS:	$(CFGDIR)/%.ip $(CFGDIR)/%.traceroute $(CFGDIR)/%.nmap
%.ip:		$(CFGDIR)/%.ip.log;		@echo "Done with $@."
%.traceroute:	$(CFGDIR)/%.traceroute.log;	@echo "Done with $@."
%.nmap:		$(CFGDIR)/%.nmap.log;		@echo "Done with $@."

test_again:
		make test_clean
		make test_all

test_clean:
		rm -f $(IP_LOGS) $(TR_LOGS) $(NMAP_LOGS) $(TESTDCFG)

test_all:	$(IP_LOGS) $(TR_LOGS) $(NMAP_LOGS)
		@echo "Done with $@."

$(CFGDIR)/%.ip.log:	$(REFDIR)/%.ip $(CFGDIR)/.must_exist
		$(LOG2CFG) -s$(SCREEN) -i $< -t ip_testd -o $(TESTDCFG) > $@
$(CFGDIR)/%.traceroute.log:	$(REFDIR)/%.traceroute $(CFGDIR)/.must_exist
		$(LOG2CFG) -s$(SCREEN) -i $< -t traceroute_testd -o $(TESTDCFG) > $@
$(CFGDIR)/%.nmap.log:	$(REFDIR)/%.nmap $(CFGDIR)/.must_exist
		$(LOG2CFG) -s$(SCREEN) -i $< -t nmap_testd -o $(TESTDCFG) > $@

%:
		@echo "Invoking std_$@ rule:"
		@$(MAKE) std_$@ ORIGINAL_TARGET=$@

