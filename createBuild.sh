echo "Exporting remote url"
git config --get remote.origin.url > ./build/AppInfo/source.url
echo "source.url file is now: "
cat ./build/AppInfo/source.url

rm -rf ./build/AppInfo/App.xcarchive
rm -rf ./build/AppInfo.zip

echo "\n Starting to build app"
sleep 2

cd App
xcodebuild -scheme App -sdk iphoneos -destination generic/platform=iOS clean archive -archivePath ../build/AppInfo/App

cd ../build
echo "Making a zip file"
zip -r AppInfo.zip AppInfo

