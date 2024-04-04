## Changelog

### KiteModels v0.5.10 - 2024-04-03
#### Added

-    it is now possible (and suggested) to use the DAE solver DFBDF.

This requires adding the following line to the settings.yaml file: 

    solver: "DFBDF"

The new solver is much faster (4x average, 1.8x worst case), has a lot less memory allocations (~ 50%) and is also much more stable in highly dynamic situations.

### KiteModels v0.5.8 - 2024-04-01

#### Added
- new, non-allocating function `update_sys_state!(ss::SysState, s::AKM, zoom=1.0)`

### KiteModels v0.5.7 - 2024-04-01

#### Changed
- improved performance by 10% by implementing custom `norm()` function for 3D vectors

### KiteModels v0.5.6 - 2024-03-30

#### Fixed
- fix the method `clear!(s::KPS4)` which failed for models with less than 6 tether segments

Simulations should work fine now for one to about 28 tether segments (no hard upper limit, but things become slow and the visualization ugly if you have too many segments).