# Flipkart Playwright tests

Browser-based Flipkart tests are written with Robot Framework and the
Robot Framework Browser library (Playwright).

## Run locally

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
rfbrowser init chromium
robot --outputdir results Test
```

The local run opens a visible Chromium browser. Robot Framework writes its
`report.html` and `log.html` under `results/`.

## GitHub Actions

Every push to `main` runs all suites under `Test/` on Chromium under a virtual
display. The workflow installs the Python and browser dependencies and uploads
the Robot Framework HTML report and log as the `playwright-test-reports`
artifact, even when a test fails. Artifacts are retained for 14 days. The
workflow can also be started manually from the Actions tab.
