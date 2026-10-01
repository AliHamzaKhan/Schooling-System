# Email and push delivery setup

Companion to the [notification delivery contract](NOTIFICATION_DELIVERY_CONTRACT.md)
and the [operations runbook](OPERATIONS_RUNBOOK.md#external-provider-tests).

Every channel is **simulated** (nothing is sent, status `simulated`) until its
settings are filled in. Settings go in the backend environment (`.env` locally,
the secret manager in staging/production). Never commit them.

## Recommended providers

| Channel | Recommendation | Why |
| --- | --- | --- |
| Email | Any provider's **SMTP** endpoint: Amazon SES, SendGrid, Mailgun, Brevo or Google Workspace | Standard protocol, no extra SDK; switching provider is a settings change |
| Push (Android, iOS, web) | **Firebase Cloud Messaging HTTP v1** | Already built; one service account covers all app platforms |
| SMS / WhatsApp | Twilio (already built) | Optional; costs per message |

## Email (SMTP)

1. In the provider, verify the sending domain (SPF and DKIM DNS records) and
   create SMTP credentials. Pick a sender such as `no-reply@your-school.org`.
2. Set:

   | Setting | Example |
   | --- | --- |
   | `EMAIL_FROM` | `Meri Taleem <no-reply@your-school.org>` |
   | `SMTP_HOST` | `email-smtp.eu-west-1.amazonaws.com` / `smtp.sendgrid.net` / `smtp-relay.brevo.com` |
   | `SMTP_PORT` | `587` |
   | `SMTP_SECURITY` | `starttls` (port 587) or `ssl` (port 465) |
   | `SMTP_USERNAME`, `SMTP_PASSWORD` | the provider's SMTP credentials (SendGrid: username `apikey`) |

3. The API refuses to start if `SMTP_HOST` is set without `EMAIL_FROM`, or with
   only one of username/password.

Outcomes: the server taking the message is `accepted`; a refused recipient,
refused sender, failed login or refused connection is `failed` (nothing was
handed over); a break during the hand-off is `uncertain` and is reviewed, never
auto-resent.

## Push (Firebase Cloud Messaging)

1. Firebase console → Project settings → Service accounts → *Generate new
   private key*. Keep the JSON file secret.
2. Set exactly one of `FIREBASE_CREDENTIALS_FILE` (path on the server),
   `FIREBASE_CREDENTIALS_JSON` (contents) or `FIREBASE_CREDENTIALS_JSON_B64`
   (base64 of the contents, safest for CI/CD variables).
3. The mobile/web apps register their device token after sign-in; no further
   backend change is needed.

## Verify with a test recipient

After deploying the settings, send one synthetic message to an address or
device **you control** (never a student, guardian or staff member):

```bash
cd backend
python scripts/send_test_notification.py --channel email \
  --to ops-test@your-school.org --approved-test-recipient
python scripts/send_test_notification.py --channel push \
  --to <your-test-device-token> --approved-test-recipient
```

The command prints `accepted`, `failed`, `simulated` or `uncertain` without the
address or message text, and exits non-zero unless the provider accepted it.
`accepted` means the provider took the message; confirm it arrived on the test
inbox/device and record the result (date, channel, operator) in the release
notes.

## What still needs a person

- Choose the email provider and verify the sending domain (DNS access).
- Create the Firebase project/service account and give the credentials to the
  deployment's secret manager.
- Run the two test sends above on staging and confirm arrival.
