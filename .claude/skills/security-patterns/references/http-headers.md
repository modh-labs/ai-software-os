# HTTP Security Headers Configuration

Every `next.config.mjs` MUST include these headers:

```typescript
async headers() {
  return [
    {
      source: "/(.*)",
      headers: [
        { key: "X-Content-Type-Options", value: "nosniff" },
        { key: "X-Frame-Options", value: "DENY" },
        { key: "X-XSS-Protection", value: "1; mode=block" },
        { key: "Referrer-Policy", value: "origin-when-cross-origin" },
      ],
    },
  ];
}
```

| Header | Purpose |
|--------|---------|
| `X-Content-Type-Options` | Prevents MIME type sniffing (stops XSS via file uploads) |
| `X-Frame-Options` | Blocks iframe embedding (prevents clickjacking) |
| `X-XSS-Protection` | Browser XSS filter (legacy browsers) |
| `Referrer-Policy` | Controls URL sharing in requests (limits data leakage) |
