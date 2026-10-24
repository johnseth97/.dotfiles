-- Layouts assign the main 1Password app to workspace 5. Auxiliary windows
-- override that assignment after the generated layout rules have loaded.
o.window(
  { class = "^(1[pP]assword|com\\.onepassword\\.OnePassword)$", title = "^(Quick Access — 1Password|1Password|.*[Aa]uthori[sz].*|.*[Aa]uthentication.*)$" },
  { workspace = "unset", float = true, center = true }
)

-- Also catch modal prompts regardless of their localized window title.
o.window(
  { class = "^(1[pP]assword|com\\.onepassword\\.OnePassword)$", modal = true },
  { workspace = "unset", float = true, center = true }
)

-- Leave spare columns for the 81-column Omarchy logo with Berkeley Mono.
o.window("org.omarchy.terminal", { size = { 915, 600 }, min_size = { 915, 600 } })
