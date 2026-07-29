# Figma Links + MCP Runbook

## MCP status
- `figma` MCP server is configured in Codex CLI (`codex mcp list`).
- Active target team:
  - Team name: `Tucker's Starter team`
  - Team plan key: `team::1564526061709979847`
- File created and active:
  - File key: `L048vSnClZzC9fxoT1Pyvl`
  - File URL: `https://www.figma.com/design/L048vSnClZzC9fxoT1Pyvl`

## Target file
- Rename target file to: `Flipping Seven Calculator iOS Overhaul v2`
- Imported board nodes (v2 high-fidelity capture set):
  - `00 Foundations`: `https://www.figma.com/design/L048vSnClZzC9fxoT1Pyvl?node-id=9-2`
  - `01 Components`: `https://www.figma.com/design/L048vSnClZzC9fxoT1Pyvl?node-id=8-2`
  - `02 Flows`: `https://www.figma.com/design/L048vSnClZzC9fxoT1Pyvl?node-id=7-2`
  - `03 Motion`: `https://www.figma.com/design/L048vSnClZzC9fxoT1Pyvl?node-id=6-2`
  - `04 App Store Assets`: `https://www.figma.com/design/L048vSnClZzC9fxoT1Pyvl?node-id=5-2`
  - `99 Archive/Legacy`: `https://www.figma.com/design/L048vSnClZzC9fxoT1Pyvl?node-id=4-2`

## Link placeholders
- Figma file: `https://www.figma.com/design/L048vSnClZzC9fxoT1Pyvl`
- Published component library: `TBD`
- Motion board permalink: `https://www.figma.com/design/L048vSnClZzC9fxoT1Pyvl?node-id=6-2`
- App Store assets board permalink: `https://www.figma.com/design/L048vSnClZzC9fxoT1Pyvl?node-id=5-2`

## Operational checklist
1. Authenticate MCP session.
2. Generate capture IDs for each board target (existing file mode).
3. Open each localhost capture URL and poll each capture ID to `completed`.
4. Verify links above and rename/reorder board nodes inside Figma as needed.
5. Convert board nodes into library-ready components in `01 Components`.
6. Publish library.
