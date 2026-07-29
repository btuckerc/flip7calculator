# Research and External Sources

This repo setup follows recurring lessons from current Apple-platform agent workflows: keep repo instructions short, move deeper guidance into on-demand references, make build/test commands easy to parse, and encode product/UX expectations instead of hoping agents infer them.

## Open-Standard, Repo-Local Skills

GitHub's agent-skills documentation says project skills can live in `.github/skills`, `.claude/skills`, or `.agents/skills`. This repo uses `.agents/skills` so the setup stays repo-scoped and portable across tools.

Sources:

- https://docs.github.com/en/copilot/concepts/agents/about-agent-skills

## Swift and Apple-Platform Skill Packs Worth Knowing

Paul Hudson's SwiftUI skill explicitly targets common LLM mistakes in SwiftUI: deprecated API, accessibility misses, performance surprises, navigation, layout, state management, and modern platform guidance. It also links to companion skills for SwiftData, concurrency, and testing.

Sources:

- https://github.com/twostraws/swiftui-agent-skill
- https://github.com/twostraws/SwiftData-Agent-Skill
- https://github.com/twostraws/Swift-Concurrency-Agent-Skill
- https://github.com/twostraws/Swift-Testing-Agent-Skill
- https://github.com/twostraws/Swift-Agent-Skills

Antoine van der Lee's SwiftUI Expert skill reinforces the same pattern with deeper, topic-specific reference files for state management, view structure, performance, lists, navigation, accessibility, image optimization, and latest APIs. His repos also publish separate skills for concurrency, testing, Core Data, and Xcode build optimization.

Sources:

- https://github.com/AvdLee/SwiftUI-Agent-Skill
- https://github.com/AvdLee/Swift-Concurrency-Agent-Skill
- https://github.com/AvdLee/Swift-Testing-Agent-Skill
- https://github.com/AvdLee/Core-Data-Agent-Skill
- https://github.com/AvdLee/Xcode-Build-Optimization-Agent-Skill

Thomas Ricouard's public skills repo and the official OpenAI plugins repo both emphasize the same workflow categories: SwiftUI implementation, refactors, performance audits, debugger agents, and iOS/macOS app-building loops.

Sources:

- https://github.com/Dimillian/Skills
- https://github.com/openai/plugins

Krzysztof Zablocki's workflow argument is that agents improve when you teach them your standards and loading rules instead of letting them freestyle on every task. That idea directly shaped this repo's skill-plus-references structure.

Sources:

- https://merowing.info/tags/workflow/

## AppCreator and Paul Solt Lessons Applied Here

The user-provided Paul Solt roundup highlighted a few ideas that are especially useful for this repo:

- use real skill packs instead of one giant instruction file
- give agents a Make-based workflow instead of raw `xcodebuild`
- prefer parseable output such as `xcbeautify`
- document versioned, repeatable commands inside the repo

This repo applies those lessons with:

- a repo-local project skill
- on-demand reference files
- a Makefile
- simulator-selection and no-signing helper scripts
- clean build/test output through `xcbeautify` when installed

Related tool:

- https://github.com/cpisciotta/xcbeautify

## Apple and UX Implications

The repo also has to respect Apple's review and UX bar. The practical translation for this app is:

- keep branding generic and rights-safe
- preserve clarity and trust in the primary task flow
- treat accessibility and reduced-motion behavior as part of app quality, not polish work

Primary repo note:

- `docs/APP264401-I-path-forward.md`

## Optional Global Installs

If a human wants to improve future agents outside this repo too, these are good starting points:

```bash
npx skills add https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro
npx skills add https://github.com/avdlee/swiftui-agent-skill --skill swiftui-expert-skill
brew install xcbeautify
```

OpenAI-compatible plugins and additional public Apple-platform skills can then be layered in as needed from the repositories linked above.
