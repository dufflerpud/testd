#indx#	Makefile - Build and install testd, the testing daemon
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2024-2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
#@HDR@
#@HDR@	Permission is hereby granted, free of charge, to any person
#@HDR@	obtaining a copy of this software and associated documentation
#@HDR@	files (the "Software"), to deal in the Software without
#@HDR@	restriction, including without limitation the rights to use,
#@HDR@	copy, modify, merge, publish, distribute, sublicense, and/or
#@HDR@	sell copies of the Software, and to permit persons to whom
#@HDR@	the Software is furnished to do so, subject to the following
#@HDR@	conditions:
#@HDR@	
#@HDR@	The above copyright notice and this permission notice shall be
#@HDR@	included in all copies or substantial portions of the Software.
#@HDR@	
#@HDR@	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
#@HDR@	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
#@HDR@	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
#@HDR@	AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#@HDR@	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#@HDR@	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#@HDR@	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#@HDR@	OTHER DEALINGS IN THE SOFTWARE.
#
#hist#	2026-02-19 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	Makefile - Build and install testd, the testing daemon
########################################################################
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

