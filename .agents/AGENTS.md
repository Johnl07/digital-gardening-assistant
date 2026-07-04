# Instructions for Antigravity

- **No Auto-Installations**: Do not execute commands to download or install applications or SDKs (like Flutter, Android SDK, tools, etc.) directly on the host machine. Instead, guide the user on how they can install it themselves.

## GitHub Configuration
- **GitHub Username**: Johnl07
- **GitHub Email**: maulajohnlawrence07@gmail.com

## Web Server Rule
- **Always keep the server running**: After every `flutter build web`, always restart the web server immediately (`py -m http.server 8080 --directory build/web`). Never leave the server stopped — if the user reports `ERR_EMPTY_RESPONSE` or "localhost didn't send any data", the server is down and must be restarted right away.
