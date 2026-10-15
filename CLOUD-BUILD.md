# Build through GitHub and Codemagic

This first workflow checks compilation only. It does not produce an installable iPad app, send customer notifications, or publish anything.

1. Create a private GitHub repository for the test project.
2. Extract the ZIP. Upload the CONTENTS of the StreamDeck-iPad-Test folder to the repository root. The root must contain codemagic.yaml, Package.swift, Sources/, Tests/, and Example/. Do not upload just the ZIP, and do not nest everything inside another folder.
3. In Codemagic choose Add application, connect GitHub, and select that repository. Limit access to the intended repository where offered.
4. Choose the codemagic.yaml configuration option. Select the branch containing your uploaded files and scan/check for configuration.
5. Start the workflow named "iPad Stream Deck - unsigned compile check".
6. If it fails, download build/compile.log (or dependencies.log if dependency resolution failed) and share the error output here. Do not share signing keys or credentials.

The workflow runs Xcode on a cloud Mac and needs no Apple signing credentials. Cloud build minutes may count toward your plan; check your Codemagic account before starting.

After compilation succeeds, a separate signed build needs Apple Developer membership, a unique registered app identifier, an eligible signing profile with the Communicates with Drivers entitlement, and an installation/distribution route. No signing credentials belong in this repository.

A successful compile does not prove iPad eligibility, Square hub compatibility, or physical Stream Deck operation. Those require the on-device hardware test. Keep the test app in the foreground.

Status: configuration prepared locally; no GitHub repository created/uploaded and no Codemagic build started by this assistant.
