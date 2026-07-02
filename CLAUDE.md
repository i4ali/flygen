# FlyGen - Project Notes

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
