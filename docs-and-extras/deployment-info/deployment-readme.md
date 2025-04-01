
# Deployment working example

From log 3fef717c2391dc3b7cf72cb876489561e6f8ba16

Here is the build log of a recent working commit:

```
commit 3fef717c2391dc3b7cf72cb876489561e6f8ba16 (HEAD -> main, origin/main)
Author: Patrick Meaney <patrick.wm.meaney@gmail.com>
Date:   Tue Apr 1 11:26:14 2025 -0600

    Added postbuild process to entrypoint-- now its pnpm run build && pnpm run postbuild -- due to nextjs error of Unable to find next-sitemap.config.js or custom config file
```

So yeah, just make sure to create fresh volumes.

Another pre-req re the docker networks, but those already get created if they don't yet exist:

- In a-db-init.yml (line 111):
  `ssh prod "docker network ls --filter name=private-payloadcms-pg-dockernet -q | grep -q . || docker network create 
  private-payloadcms-pg-dockernet"`

- And similarly in b-cms-fe-check-deploy.yml (line 215):
  `ssh prod "docker network ls --filter name=private-payloadcms-pg-dockernet -q | grep -q . || docker network create 
  private-payloadcms-pg-dockernet"`


```bash
patDevOpsUser@server020525-debianNpm:~$ docker ps -a
CONTAINER ID   IMAGE                                             COMMAND                  CREATED          STATUS          PORTS                                                                                  NAMES
ffc43887bdff   ghcr.io/pmeaney/tmp-payloadcms-portfolio:latest   "docker-entrypoint.s…"   16 minutes ago   Up 16 minutes   0.0.0.0:3000->3000/tcp, :::3000->3000/tcp                                              payloadcms-cms-fe-portfolio-prod
6256ebb1261f   postgres:17                                       "docker-entrypoint.s…"   18 minutes ago   Up 18 minutes   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp                                              payloadcms-postgres-db-portfolio-prod
12c26f9e53dd   jc21/nginx-proxy-manager:latest                   "/init"                  2 days ago       Up 2 days       0.0.0.0:80-81->80-81/tcp, :::80-81->80-81/tcp, 0.0.0.0:443->443/tcp, :::443->443/tcp   nginx-proxy-mgr-020325
775e276864fe   postgres:17                                       "docker-entrypoint.s…"   2 days ago       Up 2 days       5432/tcp                                                                               postgres-for-nginx-proxy-mgr-020325
patDevOpsUser@server020525-debianNpm:~$ d logs ffc
Starting PayloadCMS application...
Waiting for PostgreSQL at payloadcms-postgres-db-portfolio-prod:5432...
PostgreSQL is ready!
Migrations directory is empty or doesn't exist, creating...
the /src/migration directory is empty.
If you would like [entrypoint.sh] to create an initial migration, comment its create migration command back into the script
For now, leaving it commented out for clarity, now that an initial migration was created on the server
Note: This is a Production-First with Local Sync migration methodology-- the remote server is the origin of truth
As needed, we pull the remote servers data to local dev machines for development
Creating initial migration...

> payloadcms-cms-fe-portfolio2025@1.0.0 payload:migrate:create /app
> cross-env NODE_OPTIONS=--no-deprecation payload migrate:create --name initial

[17:29:31] WARN: No email adapter provided. Email will be written to console. More info at https://payloadcms.com/docs/email/overview.
[17:29:31] INFO: Migration created at /app/src/migrations/20250401_172931.ts
[17:29:31] INFO: Done.
Running database migrations...

> payloadcms-cms-fe-portfolio2025@1.0.0 payload:migrate /app
> cross-env NODE_OPTIONS=--no-deprecation payload migrate --force-accept-warning

[17:29:45] WARN: No email adapter provided. Email will be written to console. More info at https://payloadcms.com/docs/email/overview.
[17:29:45] INFO: Reading migration files from /app/src/migrations
[17:29:45] INFO: Migrating: 20250401_172931
[17:29:46] INFO: Migrated:  20250401_172931 (376ms)
[17:29:46] INFO: Done.
Running Next.js build...

> payloadcms-cms-fe-portfolio2025@1.0.0 build /app
> cross-env NODE_OPTIONS=--no-deprecation next build

Attention: Next.js now collects completely anonymous telemetry regarding usage.
This information is used to shape Next.js' roadmap and prioritize features.
You can learn more, including how to opt-out if you'd not like to participate in this anonymous program, by visiting the following URL:
https://nextjs.org/telemetry

   ▲ Next.js 15.2.3
   - Environments: .env

   Creating an optimized production build ...
 ✓ Compiled successfully
   Linting and checking validity of types ...
   Collecting page data ...
   Generating static pages (0/13) ...
   Generating static pages (3/13)
   Generating static pages (6/13)
   Generating static pages (9/13)
 ✓ Generating static pages (13/13)
   Finalizing page optimization ...
   Collecting build traces ...

Route (app)                                 Size  First Load JS  Revalidate  Expire
┌ ○ /                                      163 B         195 kB
├ ○ /_not-found                            987 B         104 kB
├ ● /[slug]                                163 B         195 kB
├ ƒ /admin/[[...segments]]                 158 B         656 kB
├ ƒ /api/[...slug]                         188 B         103 kB
├ ƒ /api/graphql                           159 B         103 kB
├ ƒ /api/graphql-playground                188 B         103 kB
├ ƒ /next/exit-preview                     159 B         103 kB
├ ƒ /next/preview                          159 B         103 kB
├ ƒ /next/seed                             159 B         103 kB
├ ƒ /pages-sitemap.xml                     159 B         103 kB
├ ○ /posts                                 338 B         125 kB         10m      1y
├ ƒ /posts-sitemap.xml                     159 B         103 kB
├ ● /posts/[slug]                          372 B         151 kB
├ ● /posts/page/[pageNumber]               337 B         125 kB
└ ƒ /search                              5.14 kB         124 kB
+ First Load JS shared by all             103 kB
  ├ chunks/47b11435-adcab461b37733db.js  53.3 kB
  ├ chunks/8136-643388b42524afa4.js      46.3 kB
  └ other shared chunks (total)          3.22 kB


○  (Static)   prerendered as static content
●  (SSG)      prerendered as static HTML (uses generateStaticParams)
ƒ  (Dynamic)  server-rendered on demand


> payloadcms-cms-fe-portfolio2025@1.0.0 postbuild /app
> next-sitemap --config next-sitemap.config.cjs

✨ [next-sitemap] Loading next-sitemap config: file:///app/next-sitemap.config.cjs
✅ [next-sitemap] Generation completed
┌───────────────┬────────┐
│ (index)       │ Values │
├───────────────┼────────┤
│ indexSitemaps │ 1      │
│ sitemaps      │ 0      │
└───────────────┴────────┘
-----------------------------------------------------
 SITEMAP INDICES
-----------------------------------------------------

   ○ http://localhost:3000/sitemap.xml



> payloadcms-cms-fe-portfolio2025@1.0.0 postbuild /app
> next-sitemap --config next-sitemap.config.cjs

✨ [next-sitemap] Loading next-sitemap config: file:///app/next-sitemap.config.cjs
✅ [next-sitemap] Generation completed
┌───────────────┬────────┐
│ (index)       │ Values │
├───────────────┼────────┤
│ indexSitemaps │ 1      │
│ sitemaps      │ 0      │
└───────────────┴────────┘
-----------------------------------------------------
 SITEMAP INDICES
-----------------------------------------------------

   ○ http://localhost:3000/sitemap.xml


Starting Next.js application...

> payloadcms-cms-fe-portfolio2025@1.0.0 start /app
> cross-env NODE_OPTIONS=--no-deprecation next start

   ▲ Next.js 15.2.3
   - Local:        http://localhost:3000
   - Network:      http://172.18.0.2:3000

 ✓ Starting...
 ✓ Ready in 990ms
```