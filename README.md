[![Build Status](https://github.com/pmeaney/tmp-payloadcms-portfolio/actions/workflows/z-main.yml/badge.svg)](https://github.com/pmeaney/tmp-payloadcms-portfolio/actions/workflows/z-main.yml)


# Dockerized PayloadCMS + Postgres Portfolio Project Template

A template for local development of a PayloadCMS website.

Stack:
- Payload CMS (CMS + NextJS)
- Postgres

# Current state of the project:

Successfully deploying.  The initial migration & seeding work.
Therefore, I am going to leave this project in its current state.  

It's now a CICD Deployment Template plus a PayloadCMS Website Template.

The PayloadCMS Website Template

1. Ready to deploy
2. Ready to edit and push new changes to the server on every commit.
3. For deployment, currently, the migration process is extremely simple: The inital migration runs, at which point, you log into the browser admin, from there click the option to seed the database.  This seeds the project into a basic PayloadCMS / NextJS / PostgreSQL blog template.  
4. (From here, you'll either want to manually log in & commit those migration files (see below) or uncomment the CMS's CICD file (.github/workflows/b-cms-fe-check-deploy.yml), Lines 274-340 -- which upload the files from their bindmount location (the remote server's directory `/home/ghaCICDDevOpsUser/payloadcms-cms-fe-portfolio2025__migrations` to the github repo).  It's left in for reference.  More info below.)


## Current state 

#### Build Log

The successful build log is available at: [successful-build-log.md](docs-and-extras/successful-build/successful-build-log.md)

#### Screenshots

Screenshots of the deployment of the Official [PayloadCMS Website Template](https://github.com/payloadcms/payload/tree/main/templates/website) via the dockerized CICD Deployment process I setup (.github/workflows)

![Logo](docs-and-extras/successful-build/post-migration-seed-1.jpg)

![Logo](docs-and-extras/successful-build/post-migration-seed-2.jpg)

![Logo](docs-and-extras/successful-build/post-migration-seed-3.jpg)


# Keep in mind

**CICD / Migration Caveat**

In the CMS's CICD file (.github/workflows/b-cms-fe-check-deploy.yml), Lines 274-340 are commented out.  These lines, if commented back in, will commit the migration files to the github repo.  They're mostly just an experiment, at least at the stage at which this repo is:  the deployment & initial migration + auto-seeding work.  I may end up adding a new CICD file to separate out the migration process.

So, lines 274-340 are mostly just for reference.  If commented back in, on commiting to the repo, migration those files will be uploaded from the remote server to the github repo.  Note: Those lines (274-240) in the CICD workflow (which upload the migration files) run after running the project, so, on the initial run, they will not exist yet since the build & migration take about 5 minutes.  Instead, on that initial run, no migration files will be found.  Hence, they'll get uploaded on the 2nd run.  In the state of this project, I've decided to leave them out.  This makes it easy to quickly deploy the project as a fresh launch of PayloadCMS-- that is, it's setup as a template with an automated deploy & initial migration.

Moving forward, I may return to add some additions to make the project easier to run-- such as a controlled process to migrate updates to schema changes.


**Things to clear out if experimenting with deployment or schema changes**

To clear out the project from the remote server, don't forget some of these steps:

Since this project involves bind mounts, you can find those via this command:

```bash
humanDevOpsUser@server2025-debian:~$ docker inspect -f '{{json .Mounts}}' containerNameOrID

# Outputs: 
[{"Type":"bind","Source":"/home/ghaCICDDevOpsUser/payloadcms-cms-fe-portfolio2025__migrations","Destination":"/app/src/migrations","Mode":"","RW":true,"Propagation":"rprivate"}]

humanDevOpsUser@server2025-debian:~$ docker inspect -f '{{range .Mounts}}{{if eq .Type "bind"}}{{.Source}} -> {{.Destination}}{{println}}{{end}}{{end}}' containerNameOrID

# Outputs: 
/home/ghaCICDDevOpsUser/payloadcms-cms-fe-portfolio2025__migrations -> /app/src/migrations

```

We see the bind mount for the PayloadCMS is setup via the deployment (see its CICD File) is setup at this directory: /home/ghaCICDDevOpsUser/payloadcms-cms-fe-portfolio2025__migrations

Check out its parent directory... It probably shows two directories-- the CMS & DB both have a bind mind for their respective database related files.

For clearing out all data (e.g. for a fresh start, if you've run the migration before and the containers are already on the server) we'll want to remove both.

```bash
humanDevOpsUser@server2025-debian:~$ ls /home/ghaCICDDevOpsUser
payloadcms-cms-fe-portfolio2025__migrations  payloadcms-postgres-db-portfolio2025
```

So, delete both of those:
```bash
humanDevOpsUser@server2025-debian:~$ sudo rm -rf payloadcms-cms-fe-portfolio2025__migrations && \
humanDevOpsUser@server2025-debian:~$ sudo rm -rf payloadcms-postgres-db-portfolio2025
```

Next, delete the volumes used by the project

`docker volume ls`

```bash
humanDevOpsUser@server2025-debian:~$ docker volume ls
DRIVER    VOLUME NAME
local     payloadcms-postgres-data-prod
local     payloadcms-postgres-init-scripts-prod

# the CICD will re-create them if they don't exist, so don't worry about recreating them.
humanDevOpsUser@server2025-debian:~$ docker volume rm payloadcms-postgres-data-prod && docker volume rm payloadcms-postgres-init-scripts-prod

```

Now that you've deleted the bind mounts & volumes, you should be ok to delete the containers, and their data won't stick around.

You might also want to run a docker prune to delete and related docker assets:
`docker system prune -a --volume`.


# To Do

- [X] Setup CICD to deploy prod version to remote server
- [ ] Setup migration scheme
  - [ ] Production-first.  Will run initial migration on remote.  Then, will pull those files to local and commit them.  And periodically will download the data as well:
    - Setup a methodology (e.g. shell script) for Periodic Database Dumps and Restores, so local dev env has same data as remote prod env.

## Resources

- Original Repo, where I figured out a deployment methodology: 
  - [template-payloadcms-portfolio2025](https://github.com/pmeaney/template-payloadcms-portfolio2025)
- [PayloadCMS's Website Template](https://github.com/payloadcms/payload/tree/main/templates/website)


## Local dev

- Clone project
- Run `docker compose -f docker-compose.dev.yml up`


## CICD Workflow

```mermaid
flowchart TB
    GitPush[/"Push to main branch"/] --> MainWorkflow["z-main.yml
    Main Deployment Pipeline"]
    
    MainWorkflow --> DBCheckInit
    
    subgraph "Database Pipeline"
        DBCheckInit["a-db-init.yml
        Database Check & Init"]
        DBCheckInit --> CheckDBExists{"DB Container
        Exists?"}
        CheckDBExists -->|No| CreateDB["Create PostgreSQL Container
        - Create volumes
        - Configure networks
        - Set environment vars"]
        CheckDBExists -->|Yes| SkipDB["Skip Database Setup"]
    end
    
    CreateDB --> CMSFECheck
    SkipDB --> CMSFECheck
    
    subgraph "Frontend Pipeline"
        CMSFECheck["b-cms-fe-check-deploy.yml
        Frontend Check & Deploy"]
        CMSFECheck --> DownloadMarker["Download Last
        Deployment Marker"]
        DownloadMarker --> DetectChanges["Check PayloadCMS
        Directory Changes"]
        DetectChanges --> ChangesExist{"Changes
        Detected?"}
        
        ChangesExist -->|Yes| BuildPublish["Build & Publish
        Docker Image"]
        BuildPublish --> DeployFE["SSH to Server &
        Deploy Frontend
        (step-deploy--cms-fe)"]
        DeployFE --> SaveMarker["Save Deployment
        Marker Artifact"]
        
        ChangesExist -->|No| SkipFE["Skip Frontend
        Deployment"]
    end
    
    subgraph "Docker Build Process"
        BuildPublish --> DockerBuildStages["Multi-stage Dockerfile"]
        
        subgraph "Build Stages"
            subgraph "Base & Dependencies Setup"
                DockerBuildStages --> BaseImage["Base Stage
                - node:20-alpine
                - Install pnpm@10.3.0"]
                BaseImage --> DepsStage["Dependencies Stage
                - Add libc6-compat
                - Copy package.json & lock file
                - pnpm install --frozen-lockfile"]
                DepsStage --> BuilderStage["Builder Stage
                - Copy dependencies from Dependencies Stage
                - Copy all source files
                - Copy ENV_FILE to .env
                - Set SKIP_NEXTJS_BUILD flag"]
            end
            
            subgraph "Build Decision & Execution"
                BuilderStage --> SkipNextBuild{"SKIP_NEXTJS_BUILD
                = true?"}
                SkipNextBuild -->|Yes| PrepareRuntime["Prepare for Runtime Build
                - Create minimal .next
                - Set skip-build flag
                - Copy src, config files"]
                SkipNextBuild -->|No| RunBuild["Run Full Build
                - pnpm run ci
                - Build Next.js app"]
            end
            
            subgraph "Runtime Preparation"
                PrepareRuntime --> RuntimePrep["prepare-runtime Stage
                - Copy env vars, public files
                - Copy config files
                - Copy entrypoint.sh
                - Copy src/migrations"]
                RunBuild --> RuntimePrep
                
                RuntimePrep --> RuntimeBuildCheck{"SKIP_NEXTJS_BUILD
                = true?"}
                RuntimeBuildCheck -->|Yes| CopySourceFiles["Copy entire src dir
                for runtime build"]
                RuntimeBuildCheck -->|No| CopyBuildOutput["Copy built .next
                artifacts"]
                
                CopySourceFiles --> RunnerStage
                CopyBuildOutput --> RunnerStage
            end
            
            subgraph "Final Image"
                RunnerStage["Runner Stage
                - Set NODE_ENV=production
                - Install postgresql-client
                - Add nextjs user/group
                - Copy prepared files
                - Set file permissions
                - Expose port 3000"]
                RunnerStage --> FinalDockerImage[/"Docker Image
                ghcr.io/pmeaney/tmp-payloadcms-portfolio2025:latest"/]
            end
        end
    end
    
    subgraph "Deployment Process"
        DeployFE --> SSHToServer["SSH to Production Server"]
        SSHToServer --> AuthGHCR["Authenticate with
        Container Registry"]
        AuthGHCR --> CreateEnvFile["Create Prod Env File
        from PAYLOAD__SECRET_ENV_FILE"]
        CreateEnvFile --> PullImage["docker pull
        ghcr.io/pmeaney/tmp-payloadcms-portfolio2025:latest"]
        PullImage --> RemoveOldContainer["docker rm -f
        payloadcms-cms-fe-portfolio-prod"]
        RemoveOldContainer --> RunContainer["docker run
        - Set container name
        - Connect to postgres network
        - Connect to main network
        - Map port 3000
        - Inject env vars"]
        
        FinalDockerImage -.-> PullImage
    end
    
    subgraph "Container Runtime"
        RunContainer --> EntrypointScript["entrypoint.sh Execution"]
        
        EntrypointScript --> EnvCheck["Environment Checks
        - Verify DATABASE_URI
        - Verify PAYLOAD_SECRET"]
        EnvCheck --> ParseDBParams["Parse Database
        Connection Parameters
        from DATABASE_URI"]
        ParseDBParams --> WaitForDB["Wait for PostgreSQL
        (30 attempts with 3s delay)
        using pg_isready"]
        
        WaitForDB --> RunMigrations["Run Database Migrations
        pnpm run payload:migrate"]
        RunMigrations --> CheckSkipBuildFlag{".next/skip-build
        file exists?"}
        
        CheckSkipBuildFlag -->|Yes| BuildNextJS["Build Next.js
        NEXT_SKIP_DB_CONNECT=true
        pnpm run build"]
        CheckSkipBuildFlag -->|No| StartApp["Start Next.js Application
        pnpm run start"]
        BuildNextJS --> StartApp
    end
    
    subgraph "Verification & Summary"
        DeployFE --> WaitPeriod["Wait Period (4 min)"]
        WaitPeriod --> CheckContainers["docker ps -a"]
        CheckContainers --> CheckLogs["docker logs
        <containerId>"]
        
        SkipDB --> DeploySummary["Generate Deployment
        Summary"]
        CreateDB --> DeploySummary
        SkipFE --> DeploySummary
        SaveMarker --> DeploySummary
        DeploySummary --> MarkdownReport["Create Markdown Report
        - Commit details
        - Database status
        - Frontend changes
        - Action taken"]
    end
    
    classDef workflow fill:#f9f,stroke:#333,stroke-width:2px
    classDef process fill:#bbf,stroke:#333,stroke-width:1px
    classDef decision fill:#fbb,stroke:#333,stroke-width:1px
    classDef container fill:#bfb,stroke:#333,stroke-width:1px
    classDef dockerstage fill:#9de,stroke:#333,stroke-width:1px
    classDef entrypoint fill:#bfd,stroke:#333,stroke-width:1px
    
    class MainWorkflow,DBCheckInit,CMSFECheck workflow
    class DetectChanges,BuildPublish,DeployFE,RunContainer process
    class CheckDBExists,ChangesExist,CheckSkipBuildFlag,SkipNextBuild,RuntimeBuildCheck decision
    class StartApp container
    class BaseImage,DepsStage,BuilderStage,PrepareRuntime,RunBuild,RuntimePrep,RunnerStage,CopySourceFiles,CopyBuildOutput dockerstage
    class EntrypointScript,EnvCheck,ParseDBParams,WaitForDB,RunMigrations,BuildNextJS entrypoint
```