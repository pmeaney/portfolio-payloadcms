


Here are example logs from the deployment from this commit:
```
commit 421eae9f02846287fd1f2360d4599952218ef2f9 (HEAD -> main, origin/main)
Author: Patrick Meaney <patrick.wm.meaney@gmail.com>
Date:   Tue Apr 1 10:49:07 2025 -0600

    Entrypoint connecting to make migrations. So, can edit migration process from entrypoint script. forgot to delete data volumes previously...
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
CONTAINER ID   IMAGE                                             COMMAND                  CREATED         STATUS         PORTS                                                                                  NAMES
3b48e191e378   ghcr.io/pmeaney/tmp-payloadcms-portfolio:latest   "docker-entrypoint.s…"   6 minutes ago   Up 6 minutes   0.0.0.0:3000->3000/tcp, :::3000->3000/tcp                                              payloadcms-cms-fe-portfolio-prod
d9518af392a6   postgres:17                                       "docker-entrypoint.s…"   9 minutes ago   Up 9 minutes   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp                                              payloadcms-postgres-db-portfolio-prod
12c26f9e53dd   jc21/nginx-proxy-manager:latest                   "/init"                  2 days ago      Up 2 days      0.0.0.0:80-81->80-81/tcp, :::80-81->80-81/tcp, 0.0.0.0:443->443/tcp, :::443->443/tcp   nginx-proxy-mgr-020325
775e276864fe   postgres:17                                       "docker-entrypoint.s…"   2 days ago      Up 2 days      5432/tcp                                                                               postgres-for-nginx-proxy-mgr-020325
patDevOpsUser@server020525-debianNpm:~$ d logs 3b
Starting PayloadCMS application...
Waiting for PostgreSQL at payloadcms-postgres-db-portfolio-prod:5432...
PostgreSQL is ready!
Migrations directory is empty or doesn't exist, creating...
Migrations directory is empty.  Creating initial migration...

> payloadcms-cms-fe-portfolio2025@1.0.0 payload:migrate:create /app
> cross-env NODE_OPTIONS=--no-deprecation payload migrate:create --name initial

[16:52:21] WARN: No email adapter provided. Email will be written to console. More info at https://payloadcms.com/docs/email/overview.
[16:52:21] INFO: Migration created at /app/src/migrations/20250401_165221.ts
[16:52:21] INFO: Done.
Running database migrations...

> payloadcms-cms-fe-portfolio2025@1.0.0 payload:migrate /app
> cross-env NODE_OPTIONS=--no-deprecation payload migrate --force-accept-warning

[16:52:34] WARN: No email adapter provided. Email will be written to console. More info at https://payloadcms.com/docs/email/overview.
[16:52:34] INFO: Reading migration files from /app/src/migrations
[16:52:35] INFO: Migrating: 20250401_165221
[16:52:35] INFO: Migrated:  20250401_165221 (739ms)
[16:52:35] INFO: Done.
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
```