# Signing settings shared by build-app.sh and make-dmg.sh (sourced, not run).
#
# SIGN_IDENTITY: the first "Developer ID Application" certificate in the keychain (override with
#   REDLINE_SIGN_IDENTITY). Empty = ad-hoc signing: fine on this Mac, but downloads hit Gatekeeper warnings.
# NOTARY_PROFILE: keychain profile for Apple's notary service, saved once with
#   xcrun notarytool store-credentials redline-notary --apple-id <email> --team-id <team>
SIGN_IDENTITY=${REDLINE_SIGN_IDENTITY:-$(security find-identity -v -p codesigning \
    | sed -n 's/.*"\(Developer ID Application: [^"]*\)".*/\1/p' | head -1)}
NOTARY_PROFILE=${REDLINE_NOTARY_PROFILE:-redline-notary}
