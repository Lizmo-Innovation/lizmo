# Running Lizmo locally

Step by step, from a fresh terminal to the app on your phone.

Commands marked **(your terminal)** must be run by you in a normal PowerShell
window — not by Claude. Claude runs inside a sandboxed app container, so
environment variables it sets and files it writes under `AppData` are redirected
into that container and are invisible to VS Code, Gradle and your own shells.
Anything under `D:\` is shared normally.

---

## 1. Set up your environment — once

**(your terminal)** Open PowerShell (no admin needed) and paste:

```powershell
[Environment]::SetEnvironmentVariable("PUB_CACHE","D:\pub-cache","User")
[Environment]::SetEnvironmentVariable("ANDROID_HOME","D:\Android\Sdk","User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT","D:\Android\Sdk","User")
```

Then add the tools to your PATH:

```powershell
$p = [Environment]::GetEnvironmentVariable("Path","User")
$add = "D:\flutter\bin;D:\Android\Sdk\platform-tools;D:\Android\Sdk\cmdline-tools\latest\bin;D:\Android\Sdk\emulator"
[Environment]::SetEnvironmentVariable("Path", "$p;$add", "User")
```

**Close every PowerShell window and VS Code**, then open a new PowerShell.
Environment variables are read once when a process starts, so anything already
running still has the old values.

Verify:

```powershell
flutter doctor
```

All checks should pass, including **Android toolchain**. If Flutter is not found,
the PATH change did not take — reopen the terminal.

---

## 2. Start the backend

```powershell
docker compose up -d
```

From `D:\Lizmo`. This starts:

| Service | Port | Notes |
|---|---|---|
| API | 8082 | not 8080 — that port is taken on this machine |
| Postgres | 5433 | not 5432 — a native PostgreSQL owns that |
| LocalStack (S3) | 4567 | |
| Admin console | 8083 | open in a browser |

Check the API is up:

```powershell
curl http://localhost:8082/actuator/health
```

Expect `{"status":"UP"}`.

---

## 3. Prepare your phone

1. **Settings → About phone** → tap **Build number** seven times
2. **Settings → Developer options** → turn on **USB debugging**
3. Plug the phone into the PC with a USB cable
4. **Accept the "Allow USB debugging?" prompt on the phone.** It is easy to
   miss, and nothing works until you do

Verify the phone is seen:

```powershell
flutter devices
```

Your phone should be listed alongside Windows, Chrome and Edge. If it is not,
try a different cable — many charge-only cables carry no data.

---

## 4. Point the phone at the API

```powershell
adb reverse tcp:8082 tcp:8082
```

This makes `localhost:8082` **on the phone** reach the API on your PC through
the cable. It is needed because:

- `10.0.2.2`, Flutter's usual Android address for the host, only works on an
  emulator
- the phone's own `localhost` is the phone

Re-run it after unplugging the phone or rebooting it — it does not persist.

Verify:

```powershell
adb reverse --list
```

---

## 5. Run from VS Code

1. Open `D:\Lizmo` in VS Code
2. Bottom-right status bar shows the current device — click it and pick your phone
3. **Run → Start Debugging (F5)** and choose **"Lizmo — phone (USB)"**

That configuration lives in `.vscode/launch.json` and passes
`--dart-define=LIZMO_API_BASE_URL=http://localhost:8082`, which pairs with the
`adb reverse` tunnel above.

Hot reload works as you edit: save a file and the phone updates in place.

---

## What you will see

The **login screen**, with "New to Lizmo? Create an account" beneath it.

Registering with **"I rent out property"** ticked lands on the landlord rent
roll; leaving it unticked lands on the tenant home. Both screens still show
**placeholder data** — the property endpoints exist, but no screen consumes them
yet, so the rows are fixtures. Sign-in, sign-up and routing are real.

---

## If something breaks

**App loads but every request fails.** `adb reverse` is not active. Re-run step 4
— the UI renders because the fixtures are local, but login will fail.

**"Error when reading ...Pub\Cache..." during build.** The pub cache is in the
wrong place. Confirm `$env:PUB_CACHE` reads `D:\pub-cache`, then run
`flutter pub get` in `mobile`.

**"Android SDK could not be found."** `ANDROID_HOME` is not set in the shell
running the build. Check step 1, and restart VS Code.

**Phone not listed by `flutter devices`.** Usually the USB debugging prompt was
not accepted, or the cable is charge-only. `adb devices` showing
`unauthorized` means the prompt is still waiting.

---

## Optional: emulator instead of a phone

The emulator needs a system image, which is **not yet installed** — attempts
from Claude's sandbox reported success but wrote nothing. From **your** terminal:

```powershell
sdkmanager "system-images;android-36;google_apis;x86_64"
```

```powershell
avdmanager create avd -n lizmo_pixel -k "system-images;android-36;google_apis;x86_64" -d pixel_7
```

Then pick **"Lizmo — emulator"** in VS Code. That configuration needs no
`--dart-define`: the app already maps the emulator to `10.0.2.2`, and no
`adb reverse` is required.
