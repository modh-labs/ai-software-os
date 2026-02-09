import { RootProvider } from 'fumadocs-ui/provider';
import type { ReactNode } from 'react';
import { Inter } from 'next/font/google';
import './global.css';

const inter = Inter({
  subsets: ['latin'],
});

export const metadata = {
  title: {
    default: 'AI Software OS',
    template: '%s | AI Software OS',
  },
  description:
    'A complete AI-native development system for shipping production software faster. 21 skills, 4 agents, 6 commands, and battle-tested engineering guides.',
};

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" className={inter.className} suppressHydrationWarning>
      <body className="flex flex-col min-h-screen">
        <RootProvider>{children}</RootProvider>
      </body>
    </html>
  );
}
