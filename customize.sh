AUTOMOUNT=true
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=false
print_modname() {
  ui_print "Script custumizado"
  ui_print "*******************************"
  ui_print "*      @sirherobrine23        *"
  ui_print "*          (Qcom)             *"
  ui_print "*       Vanced YouTube        *"
  ui_print "*******************************"
}

EXAMPLE_REPLACE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"
REPLACE="
/system/app/YouTube
/system/app/fx
/system/app/Onedrive
/system/app/Outlook-OOBE
/system/app/Spotify
/system/app/telegram
/system/app/Whatsapp
/system/priv-app/MusicFX
"

MODDIR=${0%/*}

#custom

 ui_print "Spotify app"
  cp -af "$TMPDIR/data/app/com.spotify.music/*" "/data/app/";

set_perm $MODPATH/sqlite 0  2000 0755

set_permissions() {
  set_perm_recursive $MODPATH 0 0 0755 0644
  set_perm $MODPATH/sqlite 0  2000 0755
  set_perm_recursive  $MODPATH  0  0  0755  0644
}
