---
name: appbrain-ios-template
description: Use the AppBrain, Feature Manager, MVVM layered architecture whenever an iOS developer explicitly requests it or asks for a brand-new SwiftUI Xcode project where it can form the foundation of the product. Also use it when changing or reviewing an application already built with this architecture, or when explicitly migrating a legacy iOS application and its GCD code to AppBrain and cooperative Swift Concurrency. Do not replace an established architecture unless the developer asks.
metadata:
  short-description: Build maintainable AppBrain SwiftUI apps
---

# AppBrain iOS Application Template

Apply this repository's canonical architecture rather than reconstructing it
from this entry point.

## When to Apply this Skill

Use this skill when:

- an iOS developer explicitly asks for AppBrain architecture;
- an iOS developer asks for a brand-new SwiftUI Xcode project, allowing this
  template to become the foundation of the whole product; or
- an existing application already follows this template and needs to be built,
  changed, reviewed, or brought back into alignment; or
- an iOS developer explicitly requests that an existing application be migrated
  to AppBrain or from GCD to Swift Concurrency.

Do not impose the template on an existing application with a different
architecture unless the developer asks to adopt it.

For a legacy application migration, also read
[Legacy Application Migration](references/legacy-application-migration.md)
completely before planning or changing code.

Before designing, changing, or reviewing application architecture, read these
files completely:

1. [AppBrain iOS Application Template](APPBRAIN_IOS_APPLICATION_TEMPLATE.md)
2. [Trend Reference Architecture](ARCHITECTURE.md)

The first file defines the rules. The second shows how those rules are applied
in a real commercial-style SwiftUI application. When they differ, preserve the
canonical template and treat Trend as an implementation example to bring back
into alignment.

## Apply the Template

- Preserve the product behaviour requested by the user; architecture must not
  change the required behaviour merely to make code look simpler.
- Begin by mapping each screen, ViewModel, feature capability, Feature Manager,
  repository contract, and external implementation to its advertised folder.
- Keep SwiftUI declarative and free of business decisions. Move reusable rules
  into the Feature Manager that owns them.
- Give every unique screen its own adjacent ViewModel, conventionally stored as
  `@State private var viewModel = FeatureViewModel()`.
- Let screen Views construct their own ViewModels. ViewModels obtain live feature
  capabilities through default initializer values and retain replaceable inputs
  for tests.
- Use `AppBrain.shared` as the single production composition root and facade for
  shared feature managers. Do not place navigation or screen state in AppBrain.
- Keep feature commands directly awaitable and testable. A View may create an
  unretained Task to bridge a synchronous UI event, but it must never store a
  Task handle. Move tracked or cancellable Task ownership into that screen's
  ViewModel.
- Add no wrapper, manager, protocol, or layer unless it has an immediate,
  concrete responsibility that improves ownership or maintenance.
- Test ViewModels independently and test business rules at the Feature Manager
  boundary. Preserve required concurrency behaviour in tests.

Before finishing, use the canonical Review Checklist and verify the project
builds and its relevant tests pass.
