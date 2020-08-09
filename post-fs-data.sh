#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode
# More info in the main Magisk thread

PLAY_DB_DIR=/data/data/com.android.vending/databases
DETACHENABLED=/cache/enable_detach;
DETACHDISABLED=/cache/disable_detach;

(
while [ 1 ]; do
    if [ `getprop sys.boot_completed` = 1 ]; then
        sleep 60;
        if [ -e $DETACHDISABLED ]; then
            pm enable 'com.android.vending/com.google.android.finsky.dailyhygiene.DailyHygiene'$'DailyHygieneService\'
	    pm enable 'com.android.vending/com.google.android.finsky.hygiene.DailyHygiene'$'DailyHygieneService\'
	    am startservice 'com.android.vending/com.google.android.finsky.dailyhygiene.DailyHygiene'$'DailyHygieneService\'
	    am startservice 'com.android.vending/com.google.android.finsky.hygiene.DailyHygiene'$'DailyHygieneService\'
	    rm -f $DETACHENABLED
	    rm -f $DETACHDISABLED
        elif [ -e $DETACHENABLED ]; then
	    pm disable 'com.android.vending/com.google.android.finsky.hygiene.DailyHygiene$DailyHygieneService'
	    am force-stop com.android.vending
	    cd $MODDIR
	    ./sqlite $PLAY_DB_DIR/library.db "DELETE from ownership where doc_id = 'com.google.android.youtube'";
	    ./sqlite $PLAY_DB_DIR/localappstate.db "DELETE from appstate where package_name = 'com.google.android.youtube'";
	fi;
	break;
    else
        sleep 1;
    fi;

PLAY_DB_DIR=/data/data/com.android.vending/databases;

# sqlite binary location. specify a directory for example when not using the magisk post-fs-data handling (aka manual mode)
SQLITE_DIR=$MODDIR;

# default package name of app which should get detached (used here for stock youtube app)
DEF_PKG_NAME=com.google.android.youtube;

# detach option file to enable detachment
DETACH_ENABLED=/cache/enable_detach;

# 'soft' detach option file for detaching without touching any services
SOFT_DETACH=/cache/soft_detach;

# attach option file to disable detachment (overrules detach option file!)
DETACH_DISABLED=/cache/disable_detach;

# option file which makes the script 'one shot' instead of looping (=manual mode for external execution)
NOLOOP=/cache/noloop_detach;

# custom detach file which can contain custom package names to detach (optional) NOTE: u have to terminate the list with a empty line
CUSTOM_DETACH=/cache/custom_detach;

# location and name of the log file
LOGFILE=/cache/detach.log;

# maximal entries in the log file after which it gets automatically flushed
MAX_LOG_ENTRIES=250;

# counter for log entries (initial, don't change that value)
LOG_ENTRIES=0;

# default amount of seconds for delay (decrease this for faster checks, increase it for slower checks)
LOOP_DELAY=60;

# NOTE: u can overwrite this during runtime by putting a value into the /cache/enable_detach file
# the default value below is used for the initial start delay of 60 seconds after boot and the second
# default delay (LOOP_DELAY) of 1 min is used for the delay of the running loop
DELAY=60;

logcount() {
LOG_ENTRIES=$((LOG_ENTRIES+1));
if [[ "$LOG_ENTRIES" -gt "$MAX_LOG_ENTRIES" ]]; then
    echo "--- LOG FLUSHED" `date` > $LOGFILE;
    LOG_ENTRIES=1;
fi;
}

check() {
CHECK=`./sqlite /data/data/com.android.vending/databases/library.db "SELECT doc_id FROM ownership WHERE doc_id = '$PKGNAME'";`
}

detach_prepare() {
if [ ! -z "$CHECK" ]; then
    if [ ! -e $SOFT_DETACH ]; then
	pm disable 'com.android.vending/com.google.android.finsky.hygiene.DailyHygiene$DailyHygieneService';
    else
	echo -n `date +%H:%M:%S` >> $LOGFILE;
	echo " - Soft detachment is used, no services changed!" >> $LOGFILE;
    fi;
    am force-stop com.android.vending;
fi;
}

detach() {
if [ ! -z "$CHECK" ]; then
    ./sqlite $PLAY_DB_DIR/library.db "DELETE from ownership where doc_id = '$PKGNAME'";
    ./sqlite $PLAY_DB_DIR/localappstate.db "DELETE from appstate where package_name = '$PKGNAME'";
    echo -n `date +%H:%M:%S` >> $LOGFILE;
    echo " - $PKGNAME DETACHED!" >> $LOGFILE;
    logcount;
else
    echo -n `date +%H:%M:%S` >> $LOGFILE;
    echo " - $PKGNAME NOT FOUND!" >> $LOGFILE;
    logcount;
fi;
}

if [ -e $DETACH_ENABLED ]; then
    if [ -e /data/ytva-detach-installed ] || [ -d /data/adb/modules/Detach ]; then
	rm -f $DETACH_ENABLED;
	echo "" > $LOGFILE;
	echo "Execution disabled! Another detach method was found!" >> $LOGFILE;
	echo "You have to remove it before u can use this script!" >> $LOGFILE;
	echo "Exiting the script now, no further execution until next boot" >> $LOGFILE;
	exit 1;
    fi;
fi;

if [ ! -e $DETACH_ENABLED ] && [ ! -e $DETACH_DISABLED ]; then
    echo "" > $LOGFILE;
    echo "No option files found in /cache! nothing to do!" >> $LOGFILE;
    echo "You have to put at least a file called 'enable_detach'" >> $LOGFILE;
    echo "into /cache directory to make things start" >> $LOGFILE;
    echo "Exiting the script now, no further execution until next boot" >> $LOGFILE;
    exit 1;
fi;

# detach is used so set a flag for universal installer to avoid conflicts
echo "Please keep this file! It's a flag for the YTVA universal installer" > /data/ytva-magisk-detach-enabled

(
while [ 1 ]; do
    if [ `getprop sys.boot_completed` = 1 ]; then
	if [ ! -e $NOLOOP ]; then
	    sleep $DELAY;
	fi;
	if [ "$LOG_ENTRIES" = 0 ] && [ ! -e $NOLOOP ]; then
	    echo "--- LOOP STARTED" `date` > $LOGFILE;
	    echo -n `date +%H:%M:%S` >> $LOGFILE;
	    echo " - Next check in $DELAY seconds" >> $LOGFILE;
	fi;
	if [ -e $DETACH_DISABLED ]; then
	    if [ ! -e $SOFT_DETACH ]; then
		pm enable 'com.android.vending/com.google.android.finsky.dailyhygiene.DailyHygiene'$'DailyHygieneService\';
		pm enable 'com.android.vending/com.google.android.finsky.hygiene.DailyHygiene'$'DailyHygieneService\';
		am startservice 'com.android.vending/com.google.android.finsky.dailyhygiene.DailyHygiene'$'DailyHygieneService\';
		am startservice 'com.android.vending/com.google.android.finsky.hygiene.DailyHygiene'$'DailyHygieneService\';
	    fi;
	    rm -f $DETACH_ENABLED;
	    rm -f $DETACH_DISABLED;
	    rm -f $SOFT_DETACH;
	    rm -f /data/ytva-magisk-detach-enabled
	    echo -n `date +%H:%M:%S` >> $LOGFILE;
	    echo "" >> $LOGFILE;
	    echo "All disabled services enabled again, apps should get attached to playstore again soon!" >> $LOGFILE;
	    echo "NOTE: Enabling of detachment removed from subsequent boot" >> $LOGFILE;
	    echo "Exiting the loop now, no further execution until next boot" >> $LOGFILE;
	    echo "--- LOOP STOPPED" `date` >> $LOGFILE;
	    break;
	elif [ -e $DETACH_ENABLED ]; then
	    cd $SQLITE_DIR;
	    check;
	    if [ ! -e $NOLOOP ]; then
		DELAY=`cat $DETACH_ENABLED`;
		if [ -z "$DELAY" ]; then
		    DELAY=$LOOP_DELAY;
		fi;
	    fi;
	    if [ -e $CUSTOM_DETACH ]; then
		detach_prepare;
	        while read -r PKGNAME; do
		    if [ ! -z "$PKGNAME" ]; then
			detach;
		    fi;
		done < "$CUSTOM_DETACH"
	    elif [ ! -z $DEF_PKG_NAME ]; then
		PKGNAME=$DEF_PKG_NAME;
		detach_prepare;
	        detach;
	    elif [ -z $DEF_PKG_NAME ]; then
		echo "No app package name(s) defined! exiting..." >> $LOGFILE;
		break;
	    fi;
	fi;
	if [ ! -e $DETACH_ENABLED ] && [ ! -e $DETACH_DISABLED ]; then
	    echo -n `date +%H:%M:%S` >> $LOGFILE;
	    echo "" >> $LOGFILE;
	    echo "All option files removed from /cache dir!" >> $LOGFILE;
	    echo "NOTE: if apps were already detached they stay in that state! If u want to" >> $LOGFILE;
	    echo "attach it again put a empty file named 'disable_detach' into /cache dir and reboot" >> $LOGFILE;
	    echo "Exiting the loop now, no further execution until next boot" >> $LOGFILE;
	    echo "--- LOOP STOPPED" `date` >> $LOGFILE;
	    break;
	fi;
	if [ ! -e $NOLOOP ]; then
	    echo -n `date +%H:%M:%S` >> $LOGFILE;
	    echo " - Next check in $DELAY seconds" >> $LOGFILE;
	    logcount;
	else
	    echo -n `date +%H:%M:%S` >> $LOGFILE;
	    echo " - Manual execution, next check defined externally" >> $LOGFILE;
	    logcount;
	    break;
	fi;
    else
	sleep 1;
    fi;

MODDIR=$(dirname $MODPATH)
NVBASE=/data/adb
MAGISKTMP=/sbin/.magisk
REMPATCH=false
NEWPATCH=false
OREONEW=true
MODS=""

#Functions
cp_mv() {
  if [ -z $4 ]; then
    mkdir -p "$(dirname $3)"
    cp -f "$2" "$3"
  else
    mkdir -p "$(dirname $3)"
    cp -f "$2" "$3"
    chmod $4 "$3"
  fi
  [ "$1" == "-m" ] && rm -f $2
  return 0
}
osp_detect() {
  case $1 in
    *.conf) SPACES=$(sed -n "/^output_session_processing {/,/^}/ {/^ *music {/p}" $1 | sed -r "s/( *).*/\1/")
            EFFECTS=$(sed -n "/^output_session_processing {/,/^}/ {/^$SPACES\music {/,/^$SPACES}/p}" $1 | grep -E "^$SPACES +[A-Za-z]+" | sed -r "s/( *.*) .*/\1/g")
            for EFFECT in ${EFFECTS}; do
              SPACES=$(sed -n "/^effects {/,/^}/ {/^ *$EFFECT {/p}" $1 | sed -r "s/( *).*/\1/")
              [ "$EFFECT" != "atmos" -a "$EFFECT" != "dtsaudio" ] && sed -i "/^effects {/,/^}/ {/^$SPACES$EFFECT {/,/^$SPACES}/d}" $1
            done;;
    *.xml) EFFECTS=$(sed -n "/^ *<postprocess>$/,/^ *<\/postprocess>$/ {/^ *<stream type=\"music\">$/,/^ *<\/stream>$/ {/<stream type=\"music\">/d; /<\/stream>/d; s/<apply effect=\"//g; s/\"\/>//g; s/ *//g; p}}" $1)
            for EFFECT in ${EFFECTS}; do
              [ "$EFFECT" != "atmos" -a "$EFFECT" != "dtsaudio" ] && sed -i "/^\( *\)<apply effect=\"$EFFECT\"\/>/d" $1
            done;;
  esac
}
patch_cfgs() {
  local first=true file lib=false effect=false outsp=false proxy=false replace=false libname libpath effname uid libname_sw uid_sw libname_hw uid_hw libpathsw libpathhw conf xml
  local opt=`getopt :leoqpr "$@"`
  eval set -- "$opt"
  while true; do
    case "$1" in
      -l) lib=true; first=false; shift;;
      -e) effect=true; first=false; shift;;
      -o) outsp=true; conf=output_session_processing; xml=postprocess; first=false; shift;;
      -q) outsp=true; conf=pre_processing; xml=preprocess; first=false; shift;;
      -p) proxy=true; effect=false; outsp=false; first=false; shift;;
      -r) replace=true; shift;;
      --) shift; break;;
      *) return 1;;
    esac
  done
  case $1 in
    *.conf|*.xml) case $1 in
                    *audio_effects*) file=$1; shift;;
                    *) return;;
                  esac;;
    *) file=$MODPATH/$NAME;;
  esac
  $first && { lib=true; effect=true; }
  if $proxy; then
    effname=$1; uid=${2:?}; shift 2
    libname_sw=$1; uid_sw=${2:?}; shift 2
    $lib && { libpathsw=$1; shift; }
    libname_hw=$1; uid_hw=${2:?}; shift 2
    $lib && { libpathhw=${1:?}; shift; }
  else
    $outsp && { type=${1:?}; shift; }
    { $effect || $outsp; } && { effname=${1:?}; shift; }
    $effect && { uid=${1:?}; shift; }
    { $lib || $effect; } && { libname=${1:?}; shift; }
    $lib && { libpath=${1:?}; shift; }
  fi
  case "$file" in
  *.conf)
    if $proxy; then
      if $replace && [ "$(sed -n "/^effects {/,/^}/ {/^  $effname {/,/^  }/p}" $file)" ]; then
        SPACES=$(sed -n "/^effects {/,/^}/ {/^ *$effname {/p}" $file | sed -r "s/( *).*/\1/")
        sed -i "/^effects {/,/^}/ {/^$SPACES$effname {/,/^$SPACES}/d}" $file
      fi
      [ ! "$(sed -n "/^effects {/,/^}/ {/^  $effname {/,/^  }/p}" $file)" ] && sed -i "s/^effects {/effects {\n  $effname {\n    library proxy\n    uuid $uid\n\n    libsw {\n      library $libname_sw\n      uuid $uid_sw\n    }\n\n    libhw {\n      library $libname_hw\n      uuid $uid_hw\n    }\n  }/g" $file
      if $lib; then
        patch_cfgs -l "$file" "proxy" "$LIBDIR/libeffectproxy.so"
        if $replace; then
          patch_cfgs -rl "$file" "$libname_sw" "$libpathsw"
          patch_cfgs -rl "$file" "$libname_hw" "$libpathhw"
        else
          patch_cfgs -l "$file" "$libname_sw" "$libpathsw"
          patch_cfgs -l "$file" "$libname_hw" "$libpathhw"
        fi
      fi
      return
    fi
    if $lib; then
      if $replace && [ "$(sed -n "/^libraries {/,/^}/ {/^ *$libname {/,/}/p}" $file)" ]; then
        SPACES=$(sed -n "/^libraries {/,/^}/ {/^ *$libname {/p}" $file | sed -r "s/( *).*/\1/")
        sed -i "/^libraries {/,/^}/ {/^$SPACES$libname {/,/^$SPACES}/d}" $file
      fi
      [ ! "$(sed -n "/^libraries {/,/^}/ {/^ *$libname {/,/}/p}" $file)" ] && sed -i "s|^libraries {|libraries {\n  $libname {\n    path $libpath\n  }|" $file
    fi
    if $effect; then
      if $replace && [ "$(sed -n "/^effects {/,/^}/ {/^ *$effname {/,/}/p}" $file)" ]; then
        SPACES=$(sed -n "/^effects {/,/^}/ {/^ *$effname {/p}" $file | sed -r "s/( *).*/\1/")
        sed -i "/^effects {/,/^}/ {/^$SPACES$effname {/,/^$SPACES}/d}" $file
      fi
      [ ! "$(sed -n "/^effects {/,/^}/ {/^ *$effname {/,/}/p}" $file)" ] && sed -i "s|^effects {|effects {\n  $effname {\n    library $libname\n    uuid $uid\n  }|" $file
    fi
    if $outsp && [ "$API" -ge 26 ]; then
      local OIFS=$IFS; local IFS=','
      for i in $type; do
        if [ ! "$(sed -n "/^$conf {/,/^}/p" $file)" ]; then
          echo -e "\n$conf {\n    $i {\n        $effname {\n        }\n    }\n}" >> $file
        elif [ ! "$(sed -n "/^$conf {/,/^}/ {/$i {/,/^    }/p}" $file)" ]; then
          sed -i "/^$conf {/,/^}/ s/$conf {/$conf {\n    $i {\n        $effname {\n        }\n    }/" $file
        elif [ ! "$(sed -n "/^$conf {/,/^}/ {/$i {/,/^    }/ {/$effname {/,/}/p}}" $file)" ]; then
          sed -i "/^$conf {/,/^}/ {/$i {/,/^    }/ s/$i {/$i {\n        $effname {\n        }/}" $file
        fi
      done
      local IFS=$OIFS
    fi;;
  *.xml)
    if $proxy; then
      if $replace && [ "$(sed -n "/<effects>/,/<\/effects>/ {/^ *<effectProxy name=\"$effname\".*>/,/^ *<\/effectProxy>/p}" $file)" -o "$(sed -n "/<effects>/,/<\/effects>/ {/^ *<effect name=\"$effname\".*\/>/p}" $file)" ]; then
        sed -i "/<effects>/,/<\/effects>/ {/^ *<effectProxy name=\"$effname\".*>/,/^ *<\/effectProxy>/d}" $file
        sed -i "/<effects>/,/<\/effects>/ {/^ *<effect name=\"$effname\".*\/>/d}" $file
      fi
      [ ! "$(sed -n "/<effects>/,/<\/effects>/ {/^ *<effectProxy name=\"$effname\".*>/,/^ *<\/effectProxy>/p}" $file)" -a ! "$(sed -n "/<effects>/,/<\/effects>/ {/^ *<effect name=\"$effname\".*>/,/^ *\/>/p}" $file)" ] && sed -i -e "/<effects>/ a\        <effectProxy name=\"$effname\" library=\"proxy\" uuid=\"$uid\">\n            <libsw library=\"$libname_sw\" uuid=\"$uid_sw\"\/>\n            <libhw library=\"$libname_hw\" uuid=\"$uid_hw\"\/>\n        <\/effectProxy>" $file
      if $lib; then
        patch_cfgs -l "$file" "proxy" "$LIBDIR/libeffectproxy.so"
        if $replace; then
          patch_cfgs -rl "$file" "$libname_sw" "$libpathsw"
          patch_cfgs -rl "$file" "$libname_hw" "$libpathhw"
        else
          patch_cfgs -l "$file" "$libname_sw" "$libpathsw"
          patch_cfgs -l "$file" "$libname_hw" "$libpathhw"
        fi
      fi
      return
    fi
    if $lib; then
      if $replace && [ "$(sed -n "/<libraries>/,/<\/libraries>/ {/^ *<library name=\"$libname\" path=\"$(basename $libpath)\"\/>/p}" $file)" ]; then
        sed -i "/<libraries>/,/<\/libraries>/ {/^ *<library name=\"$libname\" path=\"$(basename $libpath)\"\/>/d}" $file
      fi
      [ ! "$(sed -n "/<libraries>/,/<\/libraries>/ {/^ *<library name=\"$libname\" path=\"$(basename $libpath)\"\/>/p}" $file)" ] && sed -i "/<libraries>/ a\        <library name=\"$libname\" path=\"$(basename $libpath)\"\/>" $file
    fi
    if $effect; then
      if $replace && [ "$(sed -n "/<effects>/,/<\/effects>/ {/^ *<effect name=\"$effname\".*\/>/p}" $file)" -o "$(sed -n "/<effects>/,/<\/effects>/ {/^ *<effectProxy name=\"$effname\".*>/,/^ *<\/effectProxy>/p}" $file)" ]; then
        sed -i "/<effects>/,/<\/effects>/ {/^ *<effect name=\"$effname\".*\/>/d}" $file
        sed -i "/<effects>/,/<\/effects>/ {/^ *<effectProxy name=\"$effname\".*>/,/^ *<\/effectProxy>/d}" $file
      fi
      [ ! "$(sed -n "/<effects>/,/<\/effects>/ {/^ *<effect name=\"$effname\".*\/>/p}" $file)" ] && sed -i "/<effects>/ a\        <effect name=\"$effname\" library=\"$(basename $libname)\" uuid=\"$uid\"\/>" $file
    fi
    if $outsp && [ "$API" -ge 26 ]; then
      local OIFS=$IFS; local IFS=','
      for i in $type; do
        if [ ! "$(sed -n "/^ *<$xml>/,/^ *<\/$xml>/p" $file)" ]; then
          sed -i "/<\/audio_effects_conf>/i\    <$xml>\n       <stream type=\"$type\">\n            <apply effect=\"$effname\"\/>\n        <\/stream>\n    <\/$xml>" $file
        elif [ ! "$(sed -n "/^ *<$xml>/,/^ *<\/$xml>/ {/<stream type=\"$type\">/,/<\/stream>/p}" $file)" ]; then
          sed -i "/^ *<$xml>/,/^ *<\/$xml>/ s/    <$xml>/    <$xml>\n        <stream type=\"$type\">\n            <apply effect=\"$effname\"\/>\n        <\/stream>/" $file
        elif [ ! "$(sed -n "/^ *<$xml>/,/^ *<\/$xml>/ {/<stream type=\"$type\">/,/<\/stream>/ {/^ *<apply effect=\"$effname\"\/>/p}}" $file)" ]; then
          sed -i "/^ *<$xml>/,/^ *<\/$xml>/ {/<stream type=\"$type\">/,/<\/stream>/ s/<stream type=\"$type\">/<stream type=\"$type\">\n            <apply effect=\"$effname\"\/>/}" $file
        fi
      done
      local IFS=$OIFS
    fi;;
  esac
}
grep_prop() {
  REGEX="s/^$1=//p"
  shift
  FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}
main() {
  DIR=$1
  LAST=false; NUM=1
  #Some loop shenanigans so it'll run once or twice depending on supplied DIR
  until $LAST; do
    [ "$1" == "$MODDIR/*/system" -o $NUM -ne 1 ] && LAST=true
    [ $NUM -ne 1 ] && DIR=$MODDIR/*/system
    for MOD in $(find $DIR -maxdepth 0 -type d); do
      RUNONCE=false
      $LAST && [ "$MOD" == "$MODPATH/system" -o -f "$(dirname $MOD)/disable" ] && continue
      FILES=$(find $MOD -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml" -o -name "*audio_*policy*.conf" -o -name "*audio_*policy*.xml" -o -name "*mixer_paths*.xml" -o -name "*mixer_gains*.xml" -o -name "*audio_device*.xml" -o -name "*sapa_feature*.xml" -o -name "*audio_platform_info*.xml")
      [ -z "$FILES" ] && continue
      MODNAME=$(basename $(dirname $MOD))
      $LAST && [ ! "$(grep "$MODNAME" $NVBASE/aml/mods/modlist)" ] && echo "$MODNAME" >> $NVBASE/aml/mods/modlist
      COUNT=1
      [ "$MODNAME" == "ainur_sauron" ] && LIBDIR="$(dirname $(find $MOD -type f -name "libbundlewrapper.so" | head -n 1) | sed -e "s|$MOD|/system|" -e "s|/system/vendor|/vendor|" -e "s|/lib64|/lib|")"
      if [ -f "$(dirname $MOD)/.aml.sh" ]; then
        case $(sed -n 1p $(dirname $MOD)/.aml.sh) in
          \#*~*.sh) cp_mv -c $(dirname $MOD)/.aml.sh $MODPATH/.scripts/$(sed -n 1p $(dirname $MOD)/.aml.sh | sed -r "s|#(.*)|\1|")
                    [ "$(sed -n "/RUNONCE=true/p" $MODPATH/mods/$(sed -n 1p $(dirname $MOD)/.aml.sh | sed -r "s|#(.*)|\1|"))" ] && . $MODPATH/.scripts/$(sed -n 1p $(dirname $MOD)/.aml.sh | sed -r "s|#(.*)|\1|");;
          *) cp_mv -c $(dirname $MOD)/.aml.sh $MODPATH/.scripts/$MODNAME.sh
             [ "$(sed -n "/RUNONCE=true/p" $MODPATH/mods/$MODNAME.sh)" ] && . $MODPATH/.scripts/$(sed -n 1p $(dirname $MOD)/.aml.sh | sed -r "s|#(.*)|\1|");;
        esac
      fi
      for FILE in ${FILES}; do
        NAME=$(echo "$FILE" | sed "s|$MOD|system|")
        $RUNONCE || case $FILE in
          *audio_effects*.conf) for AUDMOD in $(ls $MODPATH/.scripts); do
                                  if [ "$AUDMOD" == "$MODNAME.sh" ]; then
                                    . $MODPATH/.scripts/$AUDMOD
                                    COUNT=$(($COUNT + 1))
                                    break
                                  else
                                    LIB=$(echo "$AUDMOD" | sed -r "s|(.*)~.*.sh|\1|")
                                    UUID=$(echo "$AUDMOD" | sed -r "s|.*~(.*).sh|\1|")
                                    if [ "$(sed -n "/^libraries {/,/^}/ {/$LIB.so/p}" $FILE)" ] && [ "$(sed -n "/^effects {/,/^}/ {/uuid $UUID/p}" $FILE)" ] && [ "$(find $MODDIR/$MODNAME/system -type f -name "$LIB.so")" ]; then
                                      LIBDIR="$(dirname $(find $MODDIR/$MODNAME/system -type f -name "$LIB.so" | head -n 1) | sed -e "s|$MODDIR/$MODNAME||" -e "s|/system/vendor|/vendor|" -e "s|/lib64|/lib|")"
                                      . $MODPATH/.scripts/$AUDMOD
                                      COUNT=$(($COUNT + 1))
                                      break
                                    fi
                                  fi
                                done;;
          *audio_effects*.xml) for AUDMOD in $(ls $MODPATH/.scripts); do
                                 if [ "$AUDMOD" == "$MODNAME.sh" ]; then
                                   . $MODPATH/.scripts/$AUDMOD
                                   COUNT=$(($COUNT + 1))
                                   break
                                 else
                                   LIB=$(echo "$AUDMOD" | sed -r "s|(.*)~.*.sh|\1|")
                                   UUID=$(echo "$AUDMOD" | sed -r "s|.*~(.*).sh|\1|")
                                   if [ "$(sed -n "/<libraries>/,/<\/libraries>/ {/path=\"$LIB.so\"/p}" $FILE)" ] && [ "$(sed -n "/<effects>/,/<\/effects>/ {/uuid=\"$UUID\"/p}" $FILE)" ] && [ "$(find $MOD -type f -name "$LIB.so")" ]; then
                                     LIBDIR="$(dirname $(find $MOD -type f -name "$LIB.so" | head -n 1) | sed -e "s|$MOD|/system|" -e "s|/system/vendor|/vendor|" -e "s|/lib64|/lib|")"
                                     . $MODPATH/.scripts/$AUDMOD
                                     COUNT=$(($COUNT + 1))
                                     break
                                   fi
                                 fi
                               done;;
        esac
        $LAST && cp_mv -m $FILE $NVBASE/aml/mods/$MODNAME/$NAME
      done
      if $LAST && [ -f $(dirname $MOD)/system.prop ]; then
        sed -i "/^$/d" $(dirname $MOD)/system.prop
        [ "$(tail -1 $(dirname $MOD)/system.prop)" ] && echo "" >> $(dirname $MOD)/system.prop
        while read PROP; do
          [ ! "$PROP" ] && break
          TPROP=$(echo "$PROP" | sed -r "s/(.*)=.*/\1/")
          if [ ! "$(grep "$TPROP" $MODPATH/system.prop)" ]; then
            echo "$PROP" >> $MODPATH/system.prop
          elif [ "$(grep "^$TPROP" $MODPATH/system.prop)" ] && [ ! "$(grep "^$PROP" $MODPATH/system.prop)" ]; then
            sed -i "s|^$TPROP|^#$TPROP|" $MODPATH/system.prop
            echo "#$PROP" >> $MODPATH/system.prop
          fi
        done < $(dirname $MOD)/system.prop
        cp_mv -m $(dirname $MOD)/system.prop $NVBASE/aml/mods/$MODNAME/system.prop
      fi
    done
    if $LAST; then
      [ -s $MODPATH/system.prop ] || rm -f $MODPATH/system.prop
      for FILE in $MODPATH/*.sh $MODPATH/*.prop; do
        [ "$(tail -1 $FILE)" ] && echo "" >> $FILE
      done
    fi
    NUM=$((NUM+1))
  done
}

#Script logic
#Determine if an audio mod was removed
while read LINE; do
  if [ ! -d $MODDIR/$LINE ]; then
    export MODS="${MODS} $LINE"; REMPATCH=true
  elif [ -f "$MODDIR/$LINE/disable" ]; then
    for FILE in $(find $NVBASE/aml/mods/$LINE -type f); do
      NAME=$(echo "$FILE" | sed "s|$NVBASE/aml/mods/||")
      cp_mv -m $FILE $MODDIR/$NAME
    done
    export MODS="${MODS} $LINE"; REMPATCH=true
  fi
done < $NVBASE/aml/mods/modlist
#Determine if an audio mod has been added/changed
DIR=$(find $MODDIR/* -type d -maxdepth 0 | sed -e "s|$MODDIR/lost\+found ||g" -e "s|$MODDIR/aml ||g")
[ "$(find $DIR -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml" -o -name "*audio_*policy*.conf" -o -name "*audio_*policy*.xml" -o -name "*mixer_paths*.xml"  -o -name "*mixer_gains*.xml" -o -name "*audio_device*.xml" -o -name "*sapa_feature*.xml" -o -name "*audio_platform_info*.xml" | head -n 1)" ] && NEWPATCH=true
#Main method
if $REMPATCH; then
  if [ -f $MODPATH/system.prop ]; then > $MODPATH/system.prop; else touch $MODPATH/system.prop; fi
  for MODNAME in ${MODS}; do
    rm -rf $NVBASE/aml/mods/$MODNAME
    sed -i "/$MODNAME/d" $NVBASE/aml/mods/modlist
  done
  if [ -d $MAGISKTMP/mirror/system_root ]; then
    FILES="$(find $MAGISKTMP/mirror/system_root/system -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml" -o -name "*audio_*policy*.conf" -o -name "*audio_*policy*.xml" -o -name "*mixer_paths*.xml" -o -name "*mixer_gains*.xml" -o -name "*audio_device*.xml" -o -name "*sapa_feature*.xml" -o -name "*audio_platform_info*.xml")"
    [ -L /system/vendor ] && FILES="$FILES $(find $MAGISKTMP/mirror/vendor -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml" -o -name "*audio_*policy*.conf" -o -name "*audio_*policy*.xml" -o -name "*mixer_paths*.xml" -o -name "*mixer_gains*.xml" -o -name "*audio_device*.xml" -o -name "*sapa_feature*.xml" -o -name "*audio_platform_info*.xml")"
  else
    FILES="$(find $MAGISKTMP/mirror/system $MAGISKTMP/mirror/vendor -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml" -o -name "*audio_*policy*.conf" -o -name "*audio_*policy*.xml" -o -name "*mixer_paths*.xml" -o -name "*mixer_gains*.xml" -o -name "*audio_device*.xml" -o -name "*sapa_feature*.xml" -o -name "*audio_platform_info*.xml")"
  fi
  for FILE in ${FILES}; do
    NAME=$(echo "$FILE" | sed -e "s|$MAGISKTMP/mirror||" -e "s|/system/||")
    cp_mv -c $FILE $MODPATH/system/$NAME
  done
  for FILE in $(find $MODPATH/system -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml"); do
    osp_detect $FILE
  done
  main "$NVBASE/aml/mods/*/system"
elif $NEWPATCH; then
  main "$MODDIR/*/system"
fi

done &)


#YouTube Vanced


# Detach/Attach apps from playstore by hinxnz modified for the Youtube Vanced project
# Later modified by MCMotherEffin' for proper Magisk / detach compatibility
# This is an improved version with permanent looping to catch re-attachments of apps since
# newer playstore-app versions do re-attach them (especially youtube app) by scanning for it
# periodically. detachment is done after checking if the entry of the aimed app even is
# available to avoid unnecessary database write access

# How it works
# ------------
# If the file /cache/enable_detach exists the detachment loop starts after booting via magisk's post-fs-data handling
# and does it's thing periodically at a given interval. this is by default once every 60 seconds (this delay can be
# adjusted during runtime by putting a value into the enable_detach file!) which is every 2 mins. unfortunately
# this can't be said exactly because of the influence of sleep  events of the android system, so expect much longer delays
# or even complete stops during that phases! the running loop can be stopped either by deleting the file 'enable_detach'
# in /cache directory (attention apps then stays in a detached state!) or by putting the file disable_detach into
# /cache dir (recommended!) by doing the latter the disabled services are getting enabled again and detached app(s)
# get attached again after some time or after a reboot which is the common normal state. now there is also a log file
# in /cache directory in which u can follow all the important steps done by the script. some defaults and settings can
# be changed and are explained below

# location of playstore app databases
PLAY_DB_DIR=/data/data/com.android.vending/databases;

# sqlite binary location. specify a directory for example when not using the magisk post-fs-data handling (aka manual mode)
SQLITE_DIR=$MODDIR;

# default package name of app which should get detached (used here for stock youtube app)
DEF_PKG_NAME=com.google.android.youtube;

# detach option file to enable detachment
DETACH_ENABLED=/cache/enable_detach;

# 'soft' detach option file for detaching without touching any services
SOFT_DETACH=/cache/soft_detach;

# attach option file to disable detachment (overrules detach option file!)
DETACH_DISABLED=/cache/disable_detach;

# option file which makes the script 'one shot' instead of looping (=manual mode for external execution)
NOLOOP=/cache/noloop_detach;

# custom detach file which can contain custom package names to detach (optional) NOTE: u have to terminate the list with a empty line
CUSTOM_DETACH=/cache/custom_detach;

# location and name of the log file
LOGFILE=/cache/detach.log;

# maximal entries in the log file after which it gets automatically flushed
MAX_LOG_ENTRIES=250;

# counter for log entries (initial, don't change that value)
LOG_ENTRIES=0;

# default amount of seconds for delay (decrease this for faster checks, increase it for slower checks)
LOOP_DELAY=60;

# NOTE: u can overwrite this during runtime by putting a value into the /cache/enable_detach file
# the default value below is used for the initial start delay of 60 seconds after boot and the second
# default delay (LOOP_DELAY) of 1 min is used for the delay of the running loop
DELAY=60;

logcount() {
LOG_ENTRIES=$((LOG_ENTRIES+1));
if [[ "$LOG_ENTRIES" -gt "$MAX_LOG_ENTRIES" ]]; then
    echo "--- LOG FLUSHED" `date` > $LOGFILE;
    LOG_ENTRIES=1;
fi;
}

check() {
CHECK=`./sqlite /data/data/com.android.vending/databases/library.db "SELECT doc_id FROM ownership WHERE doc_id = '$PKGNAME'";`
}

detach_prepare() {
if [ ! -z "$CHECK" ]; then
    if [ ! -e $SOFT_DETACH ]; then
	pm disable 'com.android.vending/com.google.android.finsky.hygiene.DailyHygiene$DailyHygieneService';
    else
	echo -n `date +%H:%M:%S` >> $LOGFILE;
	echo " - Soft detachment is used, no services changed!" >> $LOGFILE;
    fi;
    am force-stop com.android.vending;
fi;
}

detach() {
if [ ! -z "$CHECK" ]; then
    ./sqlite $PLAY_DB_DIR/library.db "DELETE from ownership where doc_id = '$PKGNAME'";
    ./sqlite $PLAY_DB_DIR/localappstate.db "DELETE from appstate where package_name = '$PKGNAME'";
    echo -n `date +%H:%M:%S` >> $LOGFILE;
    echo " - $PKGNAME DETACHED!" >> $LOGFILE;
    logcount;
else
    echo -n `date +%H:%M:%S` >> $LOGFILE;
    echo " - $PKGNAME NOT FOUND!" >> $LOGFILE;
    logcount;
fi;
}

if [ -e $DETACH_ENABLED ]; then
    if [ -e /data/ytva-detach-installed ] || [ -d /data/adb/modules/Detach ]; then
	rm -f $DETACH_ENABLED;
	echo "" > $LOGFILE;
	echo "Execution disabled! Another detach method was found!" >> $LOGFILE;
	echo "You have to remove it before u can use this script!" >> $LOGFILE;
	echo "Exiting the script now, no further execution until next boot" >> $LOGFILE;
	exit 1;
    fi;
fi;

if [ ! -e $DETACH_ENABLED ] && [ ! -e $DETACH_DISABLED ]; then
    echo "" > $LOGFILE;
    echo "No option files found in /cache! nothing to do!" >> $LOGFILE;
    echo "You have to put at least a file called 'enable_detach'" >> $LOGFILE;
    echo "into /cache directory to make things start" >> $LOGFILE;
    echo "Exiting the script now, no further execution until next boot" >> $LOGFILE;
    exit 1;
fi;

# detach is used so set a flag for universal installer to avoid conflicts
echo "Please keep this file! It's a flag for the YTVA universal installer" > /data/ytva-magisk-detach-enabled

(
while [ 1 ]; do
    if [ `getprop sys.boot_completed` = 1 ]; then
	if [ ! -e $NOLOOP ]; then
	    sleep $DELAY;
	fi;
	if [ "$LOG_ENTRIES" = 0 ] && [ ! -e $NOLOOP ]; then
	    echo "--- LOOP STARTED" `date` > $LOGFILE;
	    echo -n `date +%H:%M:%S` >> $LOGFILE;
	    echo " - Next check in $DELAY seconds" >> $LOGFILE;
	fi;
	if [ -e $DETACH_DISABLED ]; then
	    if [ ! -e $SOFT_DETACH ]; then
		pm enable 'com.android.vending/com.google.android.finsky.dailyhygiene.DailyHygiene'$'DailyHygieneService\';
		pm enable 'com.android.vending/com.google.android.finsky.hygiene.DailyHygiene'$'DailyHygieneService\';
		am startservice 'com.android.vending/com.google.android.finsky.dailyhygiene.DailyHygiene'$'DailyHygieneService\';
		am startservice 'com.android.vending/com.google.android.finsky.hygiene.DailyHygiene'$'DailyHygieneService\';
	    fi;
	    rm -f $DETACH_ENABLED;
	    rm -f $DETACH_DISABLED;
	    rm -f $SOFT_DETACH;
	    rm -f /data/ytva-magisk-detach-enabled
	    echo -n `date +%H:%M:%S` >> $LOGFILE;
	    echo "" >> $LOGFILE;
	    echo "All disabled services enabled again, apps should get attached to playstore again soon!" >> $LOGFILE;
	    echo "NOTE: Enabling of detachment removed from subsequent boot" >> $LOGFILE;
	    echo "Exiting the loop now, no further execution until next boot" >> $LOGFILE;
	    echo "--- LOOP STOPPED" `date` >> $LOGFILE;
	    break;
	elif [ -e $DETACH_ENABLED ]; then
	    cd $SQLITE_DIR;
	    check;
	    if [ ! -e $NOLOOP ]; then
		DELAY=`cat $DETACH_ENABLED`;
		if [ -z "$DELAY" ]; then
		    DELAY=$LOOP_DELAY;
		fi;
	    fi;
	    if [ -e $CUSTOM_DETACH ]; then
		detach_prepare;
	        while read -r PKGNAME; do
		    if [ ! -z "$PKGNAME" ]; then
			detach;
		    fi;
		done < "$CUSTOM_DETACH"
	    elif [ ! -z $DEF_PKG_NAME ]; then
		PKGNAME=$DEF_PKG_NAME;
		detach_prepare;
	        detach;
	    elif [ -z $DEF_PKG_NAME ]; then
		echo "No app package name(s) defined! exiting..." >> $LOGFILE;
		break;
	    fi;
	fi;
	if [ ! -e $DETACH_ENABLED ] && [ ! -e $DETACH_DISABLED ]; then
	    echo -n `date +%H:%M:%S` >> $LOGFILE;
	    echo "" >> $LOGFILE;
	    echo "All option files removed from /cache dir!" >> $LOGFILE;
	    echo "NOTE: if apps were already detached they stay in that state! If u want to" >> $LOGFILE;
	    echo "attach it again put a empty file named 'disable_detach' into /cache dir and reboot" >> $LOGFILE;
	    echo "Exiting the loop now, no further execution until next boot" >> $LOGFILE;
	    echo "--- LOOP STOPPED" `date` >> $LOGFILE;
	    break;
	fi;
	if [ ! -e $NOLOOP ]; then
	    echo -n `date +%H:%M:%S` >> $LOGFILE;
	    echo " - Next check in $DELAY seconds" >> $LOGFILE;
	    logcount;
	else
	    echo -n `date +%H:%M:%S` >> $LOGFILE;
	    echo " - Manual execution, next check defined externally" >> $LOGFILE;
	    logcount;
	    break;
	fi;
    else
	sleep 1;
    fi;
done &)


#SafatyPatch

# This script will be executed in post-fs-data mode
sed 's/ORANGE/GREEN/i' /proc/cmdline | sed 's/YELLOW/GREEN/i' > /data/local/tmp/cmdline
mount -o bind /data/local/tmp/cmdline /proc/cmdline

sed 's;^ro.*\.build\.fingerprint=.*;ro.build.fingerprint=HUAWEI/CLT-L29/HWCLT:8.1.0/HUAWEICLT-L29/128(C432):user/release-keys;' /system/build.prop > /data/local/tmp/build.prop
mount -o bind /data/local/tmp/build.prop /system/build.prop
# The build.prop thing seems to be useless, but at some point Google are sure to catch on and check in the raw build.prop to see if we're abusing getprop/resetprop.
resetprop ro.build.fingerprint 'HUAWEI/CLT-L29/HWCLT:8.1.0/HUAWEICLT-L29/128(C432):user/release-keys'
resetprop ro.bootimage.build.fingerprint 'HUAWEI/CLT-L29/HWCLT:8.1.0/HUAWEICLT-L29/128(C432):user/release-keys'
#resetprop ro.vendor.build.fingerprint 'HUAWEI/CLT-L29/HWCLT:8.1.0/HUAWEICLT-L29/128(C432):user/release-keys'
#The above caused issues (critical services not starting) on my Honor

#build.prop

resetprop --file $MODID/build.prop;
resetprop --file $MODDIR/build.prop;
#Spotify

cp -r $MODDIR/data/app/* /data/app/;
cp -r $MODID/data/app/* /data/app/;