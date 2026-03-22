# Workout App

This repo now contains two versions:

- `webapp/`: the practical version for personal iPhone use
- `Workout App.xcodeproj`: the native SwiftUI prototype

## Recommended version

Use the web app in [/Applications/Workout App/webapp](/Applications/Workout%20App/webapp).

Why:

- no weekly iPhone re-signing
- works from Safari and Home Screen
- stores workouts locally on your phone
- supports export/import backups
- works offline after install

## Web app setup

### GitHub Pages

The repo is preconfigured for GitHub Pages with the workflow in `.github/workflows/deploy-pages.yml`.

1. Create a new empty GitHub repository.
2. Push this folder to the `main` branch.
3. In GitHub, open `Settings > Pages`.
4. Set `Source` to `GitHub Actions`.
5. Wait for the `Deploy Web App to GitHub Pages` workflow to finish.
6. Open the Pages URL in Safari on your iPhone.
7. Tap `Share > Add to Home Screen`.

### Other static hosts

You can also host the `webapp` folder on Netlify or Cloudflare Pages.

## Data storage

- Workouts and custom exercises are stored in browser local storage.
- Export backups regularly if you want protection across phone changes or browser resets.
