# Static GeoClue location for the San Francisco Bay Area

This pins GeoClue system-wide to San Francisco city-center coordinates. It
prevents IP and network-based providers from replacing the configured point.
The coordinates are an approximation; the 25 km radius reflects city-level
precision rather than an exact address.

From the dotfiles repository root, install the files and restart GeoClue:

```sh
sudo install -o geoclue -g geoclue -m 0600 geoclue-static-bay-area/geolocation /etc/geolocation
sudo install -o root -g root -m 0644 geoclue-static-bay-area/99-static-bay-area.conf /etc/geoclue/conf.d/99-static-bay-area.conf
sudo systemctl restart geoclue.service
```

To undo the override, remove `/etc/geoclue/conf.d/99-static-bay-area.conf` and
`/etc/geolocation`, then restart `geoclue.service`.
