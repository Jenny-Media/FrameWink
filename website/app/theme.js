// Run in the head before the body paints; no hydration or external script is needed.
export const themeInitialization = `(() => {
  const key = "framewink-theme";
  const root = document.documentElement;
  const system = window.matchMedia("(prefers-color-scheme: dark)");
  const valid = (value) => value === "light" || value === "dark";
  let preference = null;

  try {
    const saved = window.localStorage.getItem(key);
    if (valid(saved)) preference = saved;
  } catch {
    // The toggle still works for this visit when storage is unavailable.
  }

  const apply = () => {
    const theme = preference || (system.matches ? "dark" : "light");
    root.dataset.theme = theme;
    // Own this metadata outside React's route metadata so hydration cannot duplicate it.
    let color = document.getElementById("framewink-theme-color");
    if (!color) {
      color = document.createElement("meta");
      color.id = "framewink-theme-color";
      color.name = "theme-color";
      document.head.appendChild(color);
    }
    color.setAttribute("content", theme === "dark" ? "#101626" : "#fffdf7");
  };

  apply();
  document.addEventListener("DOMContentLoaded", apply, { once: true });

  document.addEventListener("click", (event) => {
    if (!(event.target instanceof Element) || !event.target.closest("[data-theme-toggle]")) return;
    preference = root.dataset.theme === "dark" ? "light" : "dark";
    try {
      window.localStorage.setItem(key, preference);
    } catch {
      // Keep the in-memory choice even if it cannot be saved.
    }
    apply();
  });

  system.addEventListener("change", () => {
    if (!preference) apply();
  });

  window.addEventListener("storage", (event) => {
    if (event.key !== key && event.key !== null) return;
    preference = valid(event.newValue) ? event.newValue : null;
    apply();
  });
})();`;
