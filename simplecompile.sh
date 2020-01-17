#!/bin/bash

# The master version lives at https://github.com/pisanorg/w/wiki/simple-compile
# Submit suggestions and modification on the wiki
# Last Modified: 17 Jan 2020 - Yusuf Pisan


# Easily compile and run this program under Linux, using
#   Compiler: clang++ or g++
#   Style Checker: clang-tidy with options from .clang-tidy
#   Style Formatting: clang-format
#   using LLVM style from .clang-format
#   Memory Leak: valgrind and "ASAN_OPTIONS=detect_leaks=1" option

# Lines starting with '$' indicate what is typed on command line

# if you get the following error:
# -bash: ./simplecompile.sh: /bin/bash^M: bad interpreter: No such file or directory
# run dos2unix to fix it
# $ dos2unix simplecompile.sh

# make this file executable
# $ chmod 700 simplecompile.sh
# redirect the output and stderr from this file to output.txt
# $ ./simplecompile.sh > output.txt 2>&1

echo "==================================================================="
echo "Recommended Usage: ./simplecompile.sh > output.txt 2>&1"
echo "==================================================================="

EXIT_VALUE=0

function check_last_command() {
  LAST_COMMAND_RESULT=$?
  if [ $LAST_COMMAND_RESULT -ne 0 ]; then
    echo "---> Last command executed failed with exitcode code: $LAST_COMMAND_RESULT"
    EXIT_VALUE=$LAST_COMMAND_RESULT
  fi
}

date

# Display machine name
if hash uname 2>/dev/null; then
  uname -a
fi

# Display user name
if hash id 2>/dev/null; then
  id
fi

# Choose compiler
CC="NO-COMPILER"
if hash clang++ 2>/dev/null; then
  CC="clang++"
elif hash g++ 2>/dev/null; then
  CC="g++"
  else
  echo "*** ERROR could not find a compiler: No clang++ OR g++ ***"
  CC="echo ERROR-NO-COMPILER "
fi

echo "==================================================================="
echo "*** compiling with $CC to create an executable called myprogram"
echo "==================================================================="

$CC --version
$CC -std=c++14 -Wall -Wextra -Wno-sign-compare ./*.cpp -g -o myprogram

echo "==================================================================="
if [ -f myprogram ]; then
  echo "*** running myprogram"
  ./myprogram
  check_last_command
else
  check_last_command
  echo "*** ERROR could not find myprogram"
fi

echo "==================================================================="
if hash clang-tidy 2>/dev/null; then
  echo "*** running clang-tidy using options from .clang-tidy"
  clang-tidy --version
  clang-tidy ./*.cpp -- -std=c++14
  check_last_command
else
  echo "*** ERROR clang-tidy is not available on this system "
fi

echo "==================================================================="
if hash clang-format 2>/dev/null; then
  echo "*** running clang-format format formatting suggestions"
  echo "*** generating new .clang-format based on LLVM style"
  echo "# generated by simplecompile.sh with: " > .clang-format
  echo "# clang-format -style=llvm -dump-config > .clang-format" >> .clang-format
  clang-format -style=llvm -dump-config >> .clang-format
  for i in ./*.cpp; do
    echo "*** formatting suggestions for $i"
    clang-format "$i" | diff "$i" -
  done
else
  echo "*** ERROR clang-format is not available on this system"
fi

echo "==================================================================="
if hash valgrind 2>/dev/null; then
  if [ -f myprogram ]; then
    echo "*** running valgrind to detect memory leaks"
    valgrind --leak-check=full ./myprogram > myprogram-valgrind-output.txt 2>&1
    # default NOLEAKMSG is for CSS Linux Lab 3.10.0-957.27.2.el7.x86_64
    NOLEAKMSG="in use at exit: 0 bytes in 0 blocks"
    if [ "valgrind-3.15.0.GIT" == `valgrind --version 2> /dev/null` ]; then
      # "Using Mac Laptop, Darwin Kernel Version 16.7.0"
      NOLEAKMSG="definitely lost: 0 bytes in 0 blocks"
    fi
    grep "$NOLEAKMSG" myprogram-valgrind-output.txt
    # exit status of grep is 0 is no match found, 1 if match found
    LAST_COMMAND_RESULT=$?
    if [ $LAST_COMMAND_RESULT -eq 1 ]; then
      echo "---> grep from valgrind did not find expected string: $$NOLEAKMSG"
      echo "---> might have memory leak, seeting exitcode to 111"
      EXIT_VALUE=111
    fi
  else
    echo "*** ERROR could not find executable to test with valgrind"
  fi
else
  echo "*** ERROR valgrind is not available on this system"
fi

echo "==================================================================="
echo "*** compiling with $CC to checking for memory leaks"
$CC -std=c++14 -fsanitize=address -fno-omit-frame-pointer -g ./*.cpp -o myprogram

echo "==================================================================="
if [ -f myprogram ]; then
  echo "*** running myprogram with memory checking"
  ASAN_OPTIONS=detect_leaks=1 ./myprogram
  check_last_command
else
  check_last_command
  echo "*** ERROR could not find myprogram"
fi

# only clang++ has --analyze
if hash clang++ 2>/dev/null; then
  echo "==================================================================="
  echo "*** using --analyze option for clang++ to detect issues"
  clang++ --analyze -std=c++14 ./*.cpp > myprogram-clangstatic-output.txt 2>&1
  cat myprogram-clangstatic-output.txt
  grep --quiet "warning" myprogram-clangstatic-output.txt
  # exit status of grep is 0 is no match found, 1 if match found
  LAST_COMMAND_RESULT=$?
  if [ $LAST_COMMAND_RESULT -eq 0 ]; then
    echo "---> grep found a warning message, setting exitcode to 1"
    EXIT_VALUE=1
  fi
fi

echo "==================================================================="
echo "*** cleaning up, deleting myprogram"
rm -rf myprogram myprogram.dSYM core myprogram-valgrind-output.txt \
myprogram-clangstatic-output.txt .clang-format *.plist 2>/dev/null

echo "==================================================================="
date
echo "==================================================================="

echo "Exiting with $EXIT_VALUE"

exit $EXIT_VALUE
