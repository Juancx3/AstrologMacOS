# Makefile for building Astrolog on macOS with XQuartz (X11).
#
# Run from the Astrolog folder:
#
#     make -f macos/Makefile -j8           # build ./astrolog for this Mac
#     make -f macos/Makefile UNIVERSAL=1   # build for Apple Silicon and Intel
#     make -f macos/Makefile app           # also create Astrolog.app
#     make -f macos/Makefile clean         # remove the build files
#
# macos/install.sh calls this file; most people don't need to run it by hand.
# It lives here, separate from the original Unix Makefile, so that updating
# to a new Astrolog version doesn't produce merge conflicts.

ROOT  := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
BUILD := $(ROOT)/build
NAME  := $(ROOT)/astrolog
LAUNCHER := $(BUILD)/AstrologLauncher

X11   ?= /opt/X11

SRCS  := $(wildcard $(ROOT)/*.cpp)
OBJS  := $(patsubst $(ROOT)/%.cpp,$(BUILD)/%.o,$(SRCS))
HDRS  := $(wildcard $(ROOT)/*.h)

ifeq ($(UNIVERSAL),1)
ARCH  := -arch arm64 -arch x86_64
endif

CXXFLAGS ?= -O2
CXXFLAGS += $(ARCH) -I$(X11)/include \
  -Wno-write-strings -Wno-narrowing -Wno-comment -Wno-deprecated-declarations
LDFLAGS  += $(ARCH) -L$(X11)/lib
LDLIBS   += -lX11 -lm

.PHONY: all app clean check-x11

all: $(NAME) $(LAUNCHER)

$(NAME): $(OBJS)
	$(CXX) $(LDFLAGS) -o $@ $(OBJS) $(LDLIBS)
	@echo "Built $@"

$(BUILD)/%.o: $(ROOT)/%.cpp $(HDRS) | check-x11
	@mkdir -p $(BUILD)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# The executable of Astrolog.app (see launcher.c).
$(LAUNCHER): $(ROOT)/macos/launcher.c
	@mkdir -p $(BUILD)
	$(CC) -O2 $(ARCH) -o $@ $<

check-x11:
	@if [ ! -f "$(X11)/include/X11/Xlib.h" ]; then \
	  echo "Can't find $(X11)/include/X11/Xlib.h."; \
	  echo "Install XQuartz from https://www.xquartz.org, restart the Mac, and try again."; \
	  exit 1; \
	fi

app: $(NAME) $(LAUNCHER)
	bash "$(ROOT)/macos/make-app.sh"

clean:
	rm -rf "$(BUILD)" "$(NAME)"
