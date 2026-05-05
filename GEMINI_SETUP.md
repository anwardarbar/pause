# Gemini API Key Setup

## 1. Get your key
Go to https://aistudio.google.com/app/apikey and create a free API key.

## 2. Add your key below
Replace `YOUR_KEY_HERE` with your actual key.

```
GEMINI_API_KEY=YOUR_KEY_HERE
```

## 3. Run the app with the key

### Flutter CLI
```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
```

### VS Code — add to .vscode/launch.json
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Pause (dev)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=GEMINI_API_KEY=YOUR_KEY_HERE"
      ]
    }
  ]
}
```

### Xcode (for release builds)
Add to the Run scheme's Arguments → Environment Variables:
  Name: GEMINI_API_KEY
  Value: YOUR_KEY_HERE

## Notes
- Without a key, the app falls back to regex parsing automatically — it still works, just with less accuracy on complex inputs.
- Never commit your API key to git. Add `.vscode/launch.json` to `.gitignore` if it contains the key.
- The key is read at compile time via `String.fromEnvironment('GEMINI_API_KEY')`.
