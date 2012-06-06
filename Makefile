PREFIX=/usr/local
DESTDIR=

INSTDIR=$(DESTDIR)$(PREFIX)
INSTBIN=$(INSTDIR)/bin

all:
	@echo do nothing. try one of the targets:
	@echo
	@echo "  install"
	@echo "  uninstall"

install:
	test -d $(INSTDIR) || mkdir -p $(INSTDIR)
	test -d $(INSTBIN) || mkdir -p $(INSTBIN)

	install -m 0755 g $(INSTBIN)

	@echo
	@echo "installation completed."
	@echo
	@echo "You may want to run the following command to source g:"
	@echo
	@echo "  echo 'source \"$(INSTBIN)/g\"' >> ~/.bashrc"

uninstall:
	rm -f $(INSTBIN)/g

.PHONY: all install uninstall
