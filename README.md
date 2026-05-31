# StravaSyncer

An iOS app for uploading FIT files to your Strava account.

## Workflow

<p align="center">
  <img src="https://github.com/user-attachments/assets/efd581ad-57c2-4d67-8941-ff811a1a214a" width="260">
</p>

<details>
<summary>Show more screenshots</summary>

<p align="center">
  <img src="https://github.com/user-attachments/assets/51a990e1-be3e-4521-90e0-51bc3cef2f5a" width="240">
  <img src="https://github.com/user-attachments/assets/3bbbcfe2-84da-42ba-a343-a4dac7831e6b" width="240">
  <img src="https://github.com/user-attachments/assets/c8906897-f030-4acf-aca8-97d73b5b9e67" width="240">
  <img src="https://github.com/user-attachments/assets/8fd2c219-0b05-40bd-a336-10bf54aa75d2" width="240">
</p>

</details>

## Features
- Sign in securely with your Strava account.
- Import FIT files from the Files app.
- Extract activity information from the FIT file name.
- Upload activities directly to Strava.
- Detect duplicate activities before uploading.
- Open existing activities directly in Strava.

## Screenshots

### Homepage

The home screen provides quick access to authentication and file selection.

### After Login

After signing in, your Strava account information is displayed and you can select a FIT file to upload.

### After Selecting a FIT File

Activity information is extracted from the file name. Currently, only Magene-generated FIT files are supported.

### Uploading

The upload progress is displayed in real time while the activity is being uploaded to Strava.

### Duplicate Activity Detection

If the activity already exists on Strava, the app displays a notification banner. Tapping the banner opens the existing activity directly in Strava.

## Requirements

- iOS 17.0 or later
- A Strava account

## TODO
- Multilingual

## License

MIT License
