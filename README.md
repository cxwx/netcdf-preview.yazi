# netcdf-preview.yazi

A Yazi plugin for previewing NetCDF files.

## Requirements

- [netcdf](https://www.unidata.ucar.edu/software/netcdf/) - Install via:
  - macOS: `brew install netcdf`
  - Linux: `apt-get install netcdf-bin` (Debian/Ubuntu)

## Installation

```bash
# Clone to your yazi plugins directory
git clone https://github.com/yourusername/netcdf-preview.yazi.git ~/.config/yazi/plugins/netcdf-preview.yazi
```

Add to your `yazi.toml`:

```toml
[[plugin.prepend_previewers]]
url = "*.nc"
run = "netcdf-preview"

[[plugin.prepend_previewers]]
url = "*.NC"
run = "netcdf-preview"

[[plugin.prepend_previewers]]
url = "*.netcdf"
run = "netcdf-preview"
```

## Preview

The plugin displays:

- **Dimensions** - NetCDF dimensions with sizes
- **Variables** - Variable types, names, dimensions, and attributes
- **Global Attributes** - File-level metadata

Example output:

```
NetCDF File

Dimensions:
  time = UNLIMITED ; // (68394 currently)

Variables:
  int: time (time)
    time.long_name = "sample time"
    time.units = "seconds since 1.1.2001, 00:00:00"
  float: LWP (time)
    LWP.long_name = "LWP Data"
    LWP.units = "g / m^2"

Global Attributes:
  Radiometer_System = "RPG-HATPRO"
  Station_Altitude = "200"
```

## License

MIT