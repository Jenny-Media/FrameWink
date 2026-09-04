import type { Metadata, Viewport } from "next";
import { SiteFooter, SiteHeader } from "./components/SiteChrome";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://frame.jenny.media"),
  title: {
    default: "FrameWink — Your private smart photo frame",
    template: "%s · FrameWink",
  },
  description:
    "Turn an iPad or iPhone into a calm, private photo frame. FrameWink never uploads your photos.",
  alternates: { canonical: "/" },
  applicationName: "FrameWink",
  category: "Photo & Video",
  keywords: [
    "digital photo frame",
    "iPad photo frame",
    "iPhone photo frame",
    "private photo app",
    "smart photo reel",
  ],
  authors: [{ name: "Jenny Media LLC", url: "https://jenny.media" }],
  creator: "Jenny Media LLC",
  publisher: "Jenny Media LLC",
  openGraph: {
    type: "website",
    locale: "en_US",
    url: "/",
    siteName: "FrameWink",
    title: "FrameWink — Your private smart photo frame",
    description:
      "Turn an iPad or iPhone into a calm, private photo frame. FrameWink never uploads your photos.",
    images: [
      {
        url: "/og.png",
        width: 1200,
        height: 630,
        alt: "FrameWink — Your photos. Beautifully framed.",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "FrameWink — Your private smart photo frame",
    description:
      "Turn an iPad or iPhone into a calm, private photo frame. FrameWink never uploads your photos.",
    images: ["/og.png"],
  },
};

export const viewport: Viewport = {
  colorScheme: "light",
  themeColor: "#fffdf7",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>
        <SiteHeader />
        {children}
        <SiteFooter />
      </body>
    </html>
  );
}
