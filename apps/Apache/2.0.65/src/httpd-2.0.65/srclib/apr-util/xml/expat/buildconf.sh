#! /bin/sh

#
# Find libtoolize. Prefer 1.x versions.
#
libtoolize=`conftools/PrintPath glibtoolize1 glibtoolize libtoolize libtoolize15 libtoolize14`
if [ "x$libtoolize" = "x" ]; then
    echo "libtoolize not found in path"
    exit 1
fi

#
# Create the libtool helper files
#
# Note: we copy (rather than link) the files.
#
# Note: This bundled version of expat will not always replace the
# files since we have a special config.guess/config.sub that we
# want to ensure is used.
echo "Copying libtool helper files ..."

# Remove any m4 cache and libtool files so one can switch between 
# autoconf and libtool versions by simply rerunning the buildconf script.
#
m4files='lt~obsolete.m4 ltversion.m4 ltoptions.m4 argz.m4 ltsugar.m4 libtool.m4'

(cd conftools ; rm -f ltconfig ltmain.sh aclocal.m4 $m4files)
rm -rf autom4te*.cache aclocal.m4

$libtoolize --copy --automake

#
# find libtool.m4
#
if [ ! -f libtool.m4 ]; then
  ltpath=`dirname $libtoolize`
  ltfile=${LIBTOOL_M4-`cd $ltpath/../share/aclocal ; pwd`/libtool.m4}
  if [ -f $ltfile ]; then
    echo "libtool.m4 found at $ltfile"
    cp $ltfile conftools/libtool.m4
  else
    echo "libtool.m4 not found - aborting!"
    exit 1
  fi
fi

#
# Build aclocal.m4 from libtool's m4 files
#
echo "dnl THIS FILE IS AUTOMATICALLY GENERATED BY buildconf.sh" > aclocal.m4
echo "dnl edits here will be lost" >> aclocal.m4

for m4file in $m4files
do
  m4file=conftools/$m4file
  if [ -f $m4file ]; then
    echo "Incorporating $m4file into aclocal.m4 ..."
    cat $m4file >> aclocal.m4
    rm -f $m4file
  fi
done

cross_compile_warning="warning: AC_TRY_RUN called without default to allow cross compiling"

#
# Generate the autoconf header template (config.h.in) and ./configure
#
echo "Creating config.h.in ..."
${AUTOHEADER:-autoheader} 2>&1 | grep -v "$cross_compile_warning"

echo "Creating configure ..."
### do some work to toss config.cache?
${AUTOCONF:-autoconf} 2>&1 | grep -v "$cross_compile_warning"

# Remove autoconf caches
rm -rf autom4te*.cache aclocal.m4

exit 0
