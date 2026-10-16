import { globSync as findDirectories } from "tinyglobby";

// Next's lint plugin only uses globSync to find project directories. Disable
// tinyglobby's directory expansion to preserve fast-glob's literal-root behavior.
export function globSync(patterns, options) {
  return findDirectories(patterns, { ...options, expandDirectories: false });
}
