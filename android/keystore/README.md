# LifeMate Release Keystore

This directory contains the encrypted LifeMate release keystore.

The actual `.jks` file is never stored in the repository.

The encrypted keystore is decrypted only inside GitHub Actions
during the signed release build.

DO NOT remove or rename the encrypted keystore file.
