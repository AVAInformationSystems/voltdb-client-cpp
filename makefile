#
# Set this to DEBUG on the command line if you want to build
# with debugging.
#
BUILD=RELEASE
ifeq (${BUILD},RELEASE)
OPTIMIZATION=-O3
endif

CC=clang++
BOOST_INCLUDES=/usr/include
BOOST_LIBS=/usr/lib/x86_64-linux-gnu

LIB_NAME=libvoltdbcpp
KIT_NAME=voltdb-client-cpp-x86_64-7.1

CFLAGS=-std=c++17 -I$(BOOST_INCLUDES) -Iinclude -D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS -g3 ${OPTIMIZATION} -fPIC
SYSTEM_LIBS := -L $(BOOST_LIBS) -lc -lpthread -lrt -lcrypto -lssl -levent_openssl -levent_pthreads -lboost_system -lboost_thread

.PHONEY: all clean test kit

OBJS := obj/Client.o \
		obj/ClientConfig.o \
		obj/ClientImpl.o \
		obj/ConnectionPool.o \
		obj/RowBuilder.o \
		obj/Table.o \
		obj/WireType.o \
		obj/Distributer.o \
		obj/MurmurHash3.o \
		obj/GeographyPoint.o \
		obj/Geography.o

TEST_OBJS := test_obj/ByteBufferTest.o \
			 test_obj/MockVoltDB.o \
			 test_obj/ClientTest.o \
			 test_obj/SerializationTest.o \
			 test_obj/GeographyPointTest.o \
			 test_obj/GeographyTest.o \
			 test_obj/TableTest.o \
			 test_obj/Tests.o

CPTEST_OBJS := test_obj/ConnectionPoolTest.o \
			 test_obj/Tests.o

RM := rm -rf

# All Target
all: $(KIT_NAME).tar.gz

obj/%.o: src/%.cpp | obj
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C++ Compiler'
	$(CC) $(CFLAGS) -c -o $@ $< -MMD -MP
	@echo 'Finished building: $<'
	@echo ' '

obj/%.o: src/%.c | obj
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C Compiler'
	$(CC) $(CFLAGS) -c -o $@ $< -MMD -MP
	@echo 'Finished building: $<'
	@echo ' '

test_obj/%.o: test_src/%.cpp | test_obj
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C Compiler'
	$(CC) $(CFLAGS) -c -o $@ $< -MMD -MP
	@echo 'Finished building: $<'
	@echo ' '

$(LIB_NAME).a: $(OBJS)
	@echo 'Building libvoltdbcpp.a static library'
	$(AR) $(ARFLAGS) $@ $?
	@echo ' '

$(LIB_NAME).so: $(OBJS)
	@echo 'Building libvoltdbcpp.so shared library'
	$(CC) -shared -o $@ $? $(SYSTEM_LIBS)
	@echo

-include $(OBJS:.o=.d)
-include $(TEST_OBJS:.o=.d)

$(KIT_NAME).tar.gz: $(LIB_NAME).a $(LIB_NAME).so
	@echo 'Building distribution kit'
	rm -rf $(KIT_NAME)
	mkdir -p $(KIT_NAME)/include/ttmath

	cp -R include/ByteBuffer.hpp include/Client.h include/ClientConfig.h \
		  include/Column.hpp include/ConnectionPool.h include/Decimal.hpp \
		  include/Exception.hpp include/InvocationResponse.hpp include/Parameter.hpp \
		  include/ParameterSet.hpp include/Procedure.hpp include/ProcedureCallback.hpp \
		  include/Row.hpp include/RowBuilder.h include/StatusListener.h include/Table.h \
		  include/TableIterator.h include/WireType.h include/TheHashinator.h \
                  include/ClientLogger.h include/Distributer.h include/ElasticHashinator.h \
                  include/MurmurHash3.h include/Geography.hpp include/GeographyPoint.hpp $(KIT_NAME)/include/
	cp -R include/ttmath/*.h $(KIT_NAME)/include/ttmath/

	cp -R examples $(KIT_NAME)/
	cp README.md $(KIT_NAME)/
	cp $(LIB_NAME).so $(KIT_NAME)/
	cp $(LIB_NAME).a $(KIT_NAME)/

	tar -czf $(KIT_NAME).tar.gz $(KIT_NAME)

	@echo

testbin: $(LIB_NAME).a $(TEST_OBJS)
	@echo 'Compiling CPPUnit tests'
	$(CC) $(CFLAGS) $(TEST_OBJS) $(LIB_NAME).a $(SYSTEM_LIBS) -lcppunit -o testbin
	@echo ' '

test: testbin
	@echo 'Running CPPUnit tests'
	./testbin
	@echo ' '

# Connection pool testing is put separately since for now it requires a local running Volt server
cptestbin: $(LIB_NAME).a $(CPTEST_OBJS)
	@echo 'Compiling Connection Pool CPPUnit tests'
	$(CC) $(CFLAGS) $(CPTEST_OBJS) $(LIB_NAME).a $(SYSTEM_LIBS) -lcppunit -o cptestbin
	@echo ' '

cptest: cptestbin
	@echo 'Running Connection Pool CPPUnit tests'
	./cptestbin
	@echo ' '

obj:
	mkdir -p obj

test_obj:
	mkdir -p test_obj

# Other Targets
clean:
	-$(RM) $(OBJS)
	-$(RM) $(OBJS:.o=.d);
	-$(RM) $(TEST_OBJS)
	-$(RM) $(TEST_OBJS:.o=.d);
	-$(RM) $(CPTEST_OBJS)
	-$(RM) testbin*
	-$(RM) cptestbin*
	-$(RM) $(LIB_NAME).a
	-$(RM) $(LIB_NAME).so
	-$(RM) $(KIT_NAME)
	-$(RM) $(KIT_NAME).tgz
	-$(RM) obj test_obj
	-@echo ' '
	-cd examples; make clean
# DO NOT DELETE
