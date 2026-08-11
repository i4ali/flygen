# FlyGen - Project Notes

## Ask before using any secret from `.env`
The `.env` file holds live API keys (e.g. OpenRouter `_TESTING` / `_PRODUCTION`). Before using ANY
key from `.env` in any way - reading its value into a command, exporting it, passing it to a deploy,
making an API call with it, or handing it to a tool - STOP and ask for explicit permission via
AskUserQuestion, then WAIT for the approve/deny answer before doing anything with the key. Do not
use the key unless it is approved; if denied, do not proceed with that action. This applies every
time, per action - a prior approval does not carry over to a later use.

## Deploy the engine as part of the build
When building the app, if the Python engine (`engine/` or the root modules it imports) changed,
redeploy it to Cloud Run too - Release builds hit the deployed engine, not your local one:
`gcloud run deploy flygen-engine --source . --region us-central1 --allow-unauthenticated --memory 1Gi --timeout 600 --set-env-vars OPENROUTER_API_KEY=<key> --quiet`

## StoreKit config
If subscriptions show "0 products" when testing, suspect the `.storekit` file first: an outdated
schema makes Xcode silently reject the whole config (even consumables fail). Before debugging
anything else, make sure `FlyGen/FlyGen/Resources/FlyGenProducts.storekit` uses the schema the
installed Xcode expects - open it in Xcode's editor; if it errors, match the format of a current
Xcode-generated `.storekit`.
