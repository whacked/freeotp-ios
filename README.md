# FreeOTP

[FreeOTP](https://freeotp.github.io/) is a two-factor authentication application for systems
utilizing one-time password protocols. Tokens can be added easily by scanning a QR code.

FreeOTP implements open standards:

* HOTP (HMAC-Based One-Time Password Algorithm) [RFC 4226](https://www.ietf.org/rfc/rfc4226.txt)
* TOTP (Time-Based One-Time Password Algorithm) [RFC 6238](https://www.ietf.org/rfc/rfc6238.txt)

This means that no proprietary server-side component is necessary: use any server-side component
that implements these standards.

## Download FreeOTP for iOS

* [App Store](https://apps.apple.com/app/freeotp-authenticator/id872559395)

## Contributing

Pull requests on GitHub are welcome under the Apache 2.0 license, see
[CONTRIBUTING](CONTRIBUTING.md) for more details.

### Install Build dependencies

All dependencies are now part of the repository. Open `FreeOTP.xcodeproj` with a recent version of Xcode, select a simulator or device, and build.
