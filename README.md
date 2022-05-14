# ClashPowerShell

[中文](README_CN.md) | English

## Features

- Support set as system proxy
- Support auto download
- Support check update
- Support IP query
- Support GitHub download proxy
- Support test Clash profile

## Configuration

```json
{
    // Clash controller URL
    "ClashControllerUrl": "http://127.0.0.1:9090",
    // Check for new Clash version once in 7 days. 0: disable update checking
    "ClashCheckPeriod": 7,
    // Last cached update checking timestamp
    "ClashLastCheck": -1,
    // Web Dashboard type. support: razord or yacd
    "WebDashboardType": "razord",
    // Check for new Web Dashboard version once in 7 days. 0: disable update checking
    "WebDashboardCheckPeriod": 7,
    // Last cached update checking timestamp
    "WebDashboardLastCheck": -1,
    // Check for new GeoIP Db version once in 3 days. 0: disable update checking
    "GeoIPDbCheckPeriod": 3,
    // Last cached update checking timestamp
    "GeoIPDbLastCheck": -1,
    // GeoIP Db download url
    "GeoIPDbDownloadUrl": "https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb",
    // Sys proxy server address
    "SysProxyServer": "127.0.0.1:7890",
    // Sys proxy bypass. Use a semicolon (;) separate
    "SysProxyBypass": "localhost;0.0.0.0;127.*;10.*;100.64.*;192.168.*;<local>",
    // IP query URL
    "IPQueryUrl": "https://myip.ipip.net",
    // GitHub download proxy URL
    "GitHubProxyUrl": ""
}
```

## License

[GNU General Public License v3.0](LICENSE)
