import type { Metadata } from "next";
import { Open_Sans } from "next/font/google";
import "./globals.css";
import Navbar from "@/components/navbar";

const sans = Open_Sans({ subsets: ["latin"] });

import { headers } from "next/headers"; // added
import ContextProvider from "@/components/context";

export const metadata: Metadata = {
  title: "Indai Stablecoin",
  description: "Stablecoin pegged to INR",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const cookies = headers().get("cookie");

  return (
    <html lang="en" className={sans.className}>
      <body className={"relative"}>
        <ContextProvider cookies={cookies}>
          <Navbar />
          <div className="h-screen pt-16 px-10 pb-20">{children}</div>
        </ContextProvider>
      </body>
    </html>
  );
}
