# Vulkan x64 libraries

The `Release.Simulator|x64` renderer links these generated libraries. Build
them with `platform/windows/Build.Tools/Build-X64Dependencies.ps1` before the
first x64 solution build. The `.lib` files are ignored by Git; a fresh clone
must run the script. It shallow-fetches the pinned [shaderc](https://github.com/google/shaderc)
revision `24275a11d81a6b33ef345878f8a4ef929c95a116` (including its pinned
glslang, SPIRV-Headers, and SPIRV-Tools dependencies) and the pinned
[SPIRV-Cross](https://github.com/KhronosGroup/SPIRV-Cross) revision
`cf1e9e0643eba07535f0015e68fd95bfe3cf1e73`. Shaderc and glslang use the
dynamic MSVC runtime (`/MD`), matching the simulator. The existing Win32 Vulkan
libraries are not changed.
