# mobile_frontend

Audiobook Store & Player – Flutter App

This is a modern, minimalistic audiobook storefront, library, and player demo, written in Flutter.

## Features

- Browse an audiobook catalog (Store) and purchase audiobooks.
- Library tab for your purchased audiobooks, progress shown for each.
- Tabbed navigation: Store, Library, Player.
- Player with: progress slider, skip 15 seconds forward/backward, persistent progress for each book.
- Local storage of user library and playback positions (uses `shared_preferences`).
- Modern, light color palette (`primary`: #3B5998, `secondary`: #8B9DC3, `accent`: #F7B32B).

## Setup

1. Install Flutter (see [Flutter Getting Started](https://flutter.dev/docs/get-started/install)).
2. Run `flutter pub get`.
3. (Optional) Edit `.env` in this directory to specify your API endpoints or configuration.
   - Example variable: `API_BASE_URL=https://example.com/api`
4. Run with `flutter run`.

## Environment Variables

- This app supports runtime environment variables via a `.env` file.
- Use [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv) to load/define additional variables if integrating an API.
- For now, the app uses only local demo data.

## Testing

Run the widget tests:
```bash
flutter test
```

## Customization

- See `lib/main.dart` for the main code structure.
- Update the catalog or API integration for your back end.

## Screenshots (Demo)

- Store: Browse audiobooks, buy or open if owned
- Library: View your purchased audiobooks and progress
- Player: Progress bar, play/pause, skip 15s

