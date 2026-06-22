# UV Index App — Phase 1

Live UV index for your current location. Flutter, Android-first.

## What's included

```
lib/
  main.dart                  app entry + theme
  models/uv_data.dart        API response models + JSON parsing
  services/
    uv_service.dart          fetches UV data, caches last result offline
    location_service.dart    geolocator wrapper with permission handling
  utils/uv_scale.dart        WHO color bands, risk labels, safety advice
  screens/home_screen.dart   main screen: loading / error / data / offline
  widgets/
    uv_dial.dart             big circular UV display
    forecast_row.dart        horizontal 24-hour forecast
pubspec.yaml                 dependencies
```

## First-time setup

You need Flutter installed (https://docs.flutter.dev/get-started/install)
and Android Studio with an emulator or a physical device.

1. Install dependencies:
   ```
   flutter pub get
   ```

2. Run it:
   ```
   flutter run
   ```

## How it works

- On launch it requests coarse location, then calls
  `currentuvindex.com/api/v1/uvi` (no API key needed).
- Shows the current UV index in a color-coded dial, safety advice, an
  estimated time-to-burn, today's peak, and a 24-hour forecast strip.
- Pull down to refresh.
- If the network or location fails, it falls back to the last cached
  reading and marks it "Offline".

## Notes & next steps

- **Time-to-burn** is a rough display heuristic, not medical advice. Phase 3
  will refine it using a user-selected skin type.
- **API**: free and keyless, rate-limited by IP. Fine for development. Before
  a heavy Play Store launch, consider OpenWeatherMap/OpenUV with a key for
  stable commercial terms (noted in the plan).
- **Phase 2** adds the home-screen widget via the `home_widget` package.
