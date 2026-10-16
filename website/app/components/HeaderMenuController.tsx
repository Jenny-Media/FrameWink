"use client";

import { useEffect } from "react";
import { initializeHeaderNavigation } from "./header-navigation";

export function HeaderMenuController() {
  useEffect(() => initializeHeaderNavigation(), []);
  return null;
}
