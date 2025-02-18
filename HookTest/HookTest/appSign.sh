#!/usr/bin/env bash
#${SRCROOT} 工程文件所在的目录
# TEMP_PATH="${SRCROOT}/Temp"
# #资源文件夹，提前在工程目录下新建一个APP文件夹，里面放ipa包
# ASSETS_PATH="${SRCROOT}/APP"
# #目标ipa包路径
# TARGET_IPA_PATH="${ASSETS_PATH}/*.ipa"
# #清空Temp文件夹
# rm -rf "${SRCROOT}/Temp"
# mkdir -p "${SRCROOT}/Temp"

# #---------------------------------------------
# # 1. 解压ipa到Temp下
# unzip -oqq "$TARGET_IPA_PATH" -d "$TEMP_PATH"
# # 拿到解压的临时的app的路径
# TEMP_APP_PATH = ${set -- "$TEMP_PATH/Payload/"*.app;echo "$1"}

TEMP_APP_PATH="/Users/vinzhou/Developer/Security/Apps/MyTest.app"

# 2. 将解压出来的.app拷贝到工程下
# BUILT_PRODUCTS_DIR 工程生成的app包的路径
# TARGET_NAME target名称
TARGET_APP_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app"
echo "app路径：$TARGET_PATH"

rm -rf "$TARGET_APP_PATH"
mkdir -p "$TARGET_APP_PATH"
cp -rf "$TEMP_APP_PATH/" "$TARGET_APP_PATH"

#----------------------------------------------
# 3. 删除extesion和WatchApp. 个人证书无法签名 Extention
rm -rf "$TARGET_APP_PATH/PlugIns"
rm -rf "$TARGET_APP_PATH/Watch"

#-----------------------------------------------
# 4. 更新info.plist文件中的CFBundleIdentifier
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $PRODUCT_BUNDLE_IDENTIFIER" "$TARGET_APP_PATH/Info.plist"

#-----------------------------------------------
# 5. 给Macho文件执行权限

# 拿到Macho文件的路径
APP_BINARY=`plutil -convert xml1 -o - $TARGET_APP_PATH/Info.plist|grep -A1 Exec|tail -n1|cut -f2 -d\>|cut -f1 -d\<`
#上可执行权限
chmod +x "$TARGET_APP_PATH/$APP_BINARY"

TARGET_APP_FRAMEWORKS_PATH="$TARGET_APP_PATH/Frameworks"

#-----------------------------------------------
# 6. 重签名第三方 Frameworks
if [ -d "$TARGET_APP_FRAMEWORKS_PATH" ];
then
for FRAMEWORK in "$TARGET_APP_FRAMEWORKS_PATH/"*
do
# 签名
/usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$FRAMEWORK"
done
fi

#------------------------------------------------
# 7. (Optional, Hook test) 注入Hook framework
# cp -r "$TARGET_APP_PATH/../MyHookFramework.framework" "$TARGET_APP_FRAMEWORKS_PATH"
yololib "$TARGET_APP_PATH/$APP_BINARY" "Frameworks/MyHookFramework.framework/MyHookFramework"
echo "注入完成"
