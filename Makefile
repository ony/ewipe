VALAC ?= valac
VALA_PKGS = posix
VALAFLAGS += $(patsubst %,--pkg=%,$(VALA_PKGS)) $(patsubst %,-X %,$(CFLAGS))

ewipe: ewipe.vala
	$(VALAC) $(VALAFLAGS) -o $(@) $(^)
