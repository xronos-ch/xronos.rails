#
# Build calibrator
#

CXX ?= g++

SRCDIR := src
BUILDDIR := build
TARGET := bin/calibrator

SRCEXT := cpp
SOURCES := $(shell find $(SRCDIR) -type f -name "*.$(SRCEXT)")
OBJECTS := $(patsubst $(SRCDIR)/%,$(BUILDDIR)/%,$(SOURCES:.$(SRCEXT)=.o))

CXXFLAGS ?= -O2 -g -Wall -std=c++14 -fmessage-length=0
CPPFLAGS ?=
LDFLAGS ?=
LDLIBS ?= -lboost_program_options

$(TARGET): $(OBJECTS)
	@mkdir -p bin
	@echo " Linking..."
	@echo " $(CXX) $^ -o $(TARGET) $(LDFLAGS) $(LDLIBS)"
	$(CXX) $^ -o $(TARGET) $(LDFLAGS) $(LDLIBS)

$(BUILDDIR)/%.o: $(SRCDIR)/%.$(SRCEXT)
	@mkdir -p $(BUILDDIR)
	@echo " $(CXX) $(CXXFLAGS) $(CPPFLAGS) -c -o $@ $<"
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c -o $@ $<

clean:
	@echo " Cleaning..."
	$(RM) -r $(BUILDDIR) $(TARGET)

tester:
	@mkdir -p bin
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) test/tester.cpp $(LDFLAGS) $(LDLIBS) -o bin/tester

ticket:
	@mkdir -p bin
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) spikes/ticket.cpp $(LDFLAGS) $(LDLIBS) -o bin/ticket