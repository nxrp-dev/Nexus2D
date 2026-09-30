# LiveServer x64 dependencies

These headers and static libraries are used only by the `Release|x64`
configuration of `platform/windows/Corona.LiveServer`. The existing Win32
`external/live-libs` submodule and its project configuration are unchanged.
The generated `.lib` files and copied headers are deliberately ignored by Git.

| Dependency | Source revision | Files |
| --- | --- | --- |
| [OpenSSL](https://github.com/openssl/openssl) | `openssl-3.5.9` (`45e844fa2a14ec92d146bd8f5778ac130b6625fb`) | `openssl/`, `libcrypto.lib`, `libssl.lib` |
| [libevent](https://github.com/libevent/libevent) | `release-2.1.13-stable` (`79ddfb460847999b807cba76d04e73891f29c6ee`) | `event2/`, `event_core.lib`, `event_extra.lib`, `event_openssl.lib` |
| [mDNSResponder](https://github.com/apple-oss-distributions/mDNSResponder) | `mDNSResponder-1557.140.5.0.1` (`f783506af3836b39b83fc14115bc2728a49db4b2`) | `dns_sd.h`, `dnssd.lib` |

Run `platform/windows/Build.Tools/Build-X64Dependencies.ps1` before the first
x64 solution build. It requires Visual C++ v142 with Windows SDK 10.0.19041.0,
Git, CMake, Ninja, Perl, and Python 3. Put CMake, Ninja, and Perl on `PATH`, or pass
`-CMakePath`, `-NinjaPath`, and `-PerlPath`. The script shallow-fetches pinned
sources into `.build/win64-deps`, builds x64 libraries, and stages the headers
and libraries at the project paths. The cache is reused on subsequent runs.
OpenSSL and libevent use the static runtime (`/MT`), as does the DNS-SD stub.
The latter loads `dnssd.dll` at run time; actual service discovery still
requires a compatible DLL and service.

The x64 LiveServer links OpenSSL and libevent statically; it does not need
OpenSSL or libevent DLLs. The Win32 LiveServer continues to use its original
libraries. The full x64 simulator build is
`MSBuild platform/windows/Corona.Simulator.sln /p:Configuration=Release /p:Platform=x64`.
