
  ┌──────────────────────┬─────────────────────┬──────────────────────────────────────────────────────────────────────┐
  │ Component            │ Placement Directory │ Purpose                                                              │
  ├──────────────────────┼─────────────────────┼──────────────────────────────────────────────────────────────────────┤
  │ Custom Commands      │ skills/             │ Place folders here containing a SKILL.md to add new /commands.       │
  │ Specialized Personas │ agents/             │ Place .md or .json files here to define agents you call with @.      │
  │ System Rules         │ instructions/       │ Place global behavior rules here to guide the agent's logic.         │
  │ Templates            │ prompts/            │ Place reusable prompt templates for complex or repetitive tasks.     │
  │ Executable Scripts   │ tools/              │ Place Python, JS, or Bash scripts here that your skills need to run. │
  │ Global Config        │ settings.json       │ The main file for managing themes, editor preferences, and API keys. │
  └──────────────────────┴─────────────────────┴──────────────────────────────────────────────────────────────────────┘

  How to use them:
   * Skills: Unlike Gemini, OpenCode usually auto-discovers everything inside the skills/ folder.
   * Discovery: If a skill isn't showing up, ensure the folder contains a valid SKILL.md with a name: and description: in the YAML
     frontmatter.
   * Persistence: Because your setup_ai.sh uses symlinks, any change you make in ~/dotfiles/ai-env/ will automatically update OpenCode.


                                                                                                                        ? for shortcuts
