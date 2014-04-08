URL="https://example.com/jenkins/job/cross-busybox/build"
PKG_VERSION="1.22.1"
BUILD_ARCH="arm"

JSON_DOC=$(cat <<'JSON_HERE'
{"parameter": [
    {"name": "PKG_NAME", "value": "busybox"},
    {"name": "PKG_VERSION", "value": ":PKG_VERSION:"},
    {"name": "TARBALL_DIR", "value": "$HOME/source"}
    {"name": "BUILD_ARCH", "value": ":BUILD_ARCH:"}
]}
JSON_HERE
)

echo -e "JSON_DOC is:\n$JSON_DOC"

JSON_POST=$(echo $JSON_DOC \
    | sed "{
    s!:BUILD_ARCH:!${BUILD_ARCH}!g;
    s!:PKG_VERSION:!${PKG_VERSION}!g;}")

echo -e "JSON_POST is:\n$JSON_POST"
exit 0

/usr/bin/curl \
    --request POST \
    $URL \
    --data-urlencode \
    json=$JSON

