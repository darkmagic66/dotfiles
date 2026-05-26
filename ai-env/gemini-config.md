✦ Here is how the Gemini CLI organizes its configuration. For Global settings (available in every project), use ~/.gemini/.

  1. Instructions (~/.gemini/instructions/)
   * What: System-level instructions or "rules" that guide the AI's behavior.
   * How: Files here aren't auto-loaded. You reference them in your GEMINI.md using @./instructions/my-rules.md.

  2. Prompts (~/.gemini/prompts/)
   * What: Reusable templates for complex tasks.
   * How: These are usually used by Skills or Sub-agents. For example, a "code-review" skill might load a specific prompt template from
     this folder.

  3. Extensions (Global Commands & Skills) (~/.gemini/extensions/)
   * What: This is where global /commands (like /backseat or /caveman) live.
   * Placement: Place the extension folder in ~/.gemini/extensions/.
   * Crucial Requirements: 
       * 1. The folder MUST have a `gemini-extension.json` file at its root to be recognized by the CLI.
       * 2. For a single skill: Place `SKILL.md` directly in the folder.
       * 3. For a collection of skills: Put the skills in subfolders and use a `GEMINI.md` at the root to import them (e.g., `<!-- Imported from: ./skills/my-skill/SKILL.md -->`).
   * Activation: You must list the extension name in ~/.gemini/extensions/extension-enablement.json.
   * Note: Use extensions/ for global commands. Use skills/ only for project-local skills referenced by a project GEMINI.md.

  4. Persona Agents (~/.gemini/agents/)
   * What: Custom sub-agents you can invoke with @agent-name.
   * Placement: Create a .json or .md file here defining the agent's persona and tools.
   * How: Once placed here, you can call them in any chat: "@refactor-expert, look at this file..."

  ---

  Summary Table

  ┌─────────────────┬─────────────────────────┬─────────────────────────────────────┐
  │ Component       │ Location                │ How it works                        │
  ├─────────────────┼─────────────────────────┼─────────────────────────────────────┤
  │ Global Rules    │ ~/.gemini/GEMINI.md     │ Auto-loaded every session.          │
  │ Global Commands │ ~/.gemini/extensions/   │ Requires extension-enablement.json. │
  │ Custom Agents   │ ~/.gemini/agents/       │ Invoked with @name.                 │
  │ Templates       │ ~/.gemini/prompts/      │ Referenced by other skills/agents.  │
  │ Context/Docs    │ ~/.gemini/instructions/ │ Referenced via @ in GEMINI.md.      │
  └─────────────────┴─────────────────────────┴─────────────────────────────────────┘

  Crucial Rule: The CLI is explicit. If you put a file in a folder, you usually still have to "point" to it in a GEMINI.md file (using @
  for instructions or <!-- Imported from --> for skills) before the AI can see it.
