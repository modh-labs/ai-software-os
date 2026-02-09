import Link from 'next/link';

export default function HomePage() {
  return (
    <main className="flex flex-1 flex-col items-center justify-center text-center px-4 py-16">
      <div className="max-w-2xl">
        <h1 className="text-4xl font-bold mb-4">AI Software OS</h1>
        <p className="text-lg text-fd-muted-foreground mb-8">
          A complete AI-native development system for shipping production
          software faster. 21 skills, 4 agents, 6 commands, and battle-tested
          engineering guides.
        </p>
        <div className="flex flex-row gap-4 justify-center">
          <Link
            href="/docs"
            className="inline-flex items-center justify-center rounded-md bg-fd-primary px-6 py-3 text-sm font-medium text-fd-primary-foreground shadow hover:bg-fd-primary/90 transition-colors"
          >
            Read the Docs
          </Link>
          <Link
            href="https://github.com/modh-ai/ai-software-os"
            className="inline-flex items-center justify-center rounded-md border border-fd-border px-6 py-3 text-sm font-medium hover:bg-fd-accent transition-colors"
          >
            GitHub
          </Link>
        </div>
      </div>
    </main>
  );
}
