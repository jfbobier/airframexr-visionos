# App Store submission

The App Store Connect record is filled in by `Actions > App Store > Run workflow` from the files in `appstore/`
(texts, keywords, review notes, `review_video_url.txt`, screenshots in `appstore/screenshots/`, 3840x2160 PNG without alpha).
Default is a dry run (fills in, submits nothing). Tick **submit** to send the build to App Review. Version and build number
are inputs (empty build = the newest valid build of that version). Release after approval is manual.

Not possible through Apple's API, done once by hand in App Store Connect: App Privacy (Data Not Collected, then Publish),
App Motion Information, EU DSA trader status, and "automatically available in new countries" off (Pricing and Availability).
Territories left out on purpose: China, South Korea, Vietnam, Russia (`EXCLUDED` in `scripts/appstore_submit.py`).
