# FlyGen - Project Notes

## StoreKit config
If subscriptions show "0 products" when testing, suspect the `.storekit` file first: an outdated
schema makes Xcode silently reject the whole config (even consumables fail). Before debugging
anything else, make sure `FlyGen/FlyGen/Resources/FlyGenProducts.storekit` uses the schema the
installed Xcode expects - open it in Xcode's editor; if it errors, match the format of a current
Xcode-generated `.storekit`.
