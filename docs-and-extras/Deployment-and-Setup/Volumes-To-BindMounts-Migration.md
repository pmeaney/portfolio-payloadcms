# Migration Guide: Switching from Named Volumes to Bind Mounts

This guide explains how to convert your PayloadCMS project from using named volumes to bind mounts, allowing you to commit migration files to your Git repository.

## Why Switch to Bind Mounts?

1. **Version Control Integration**: Bind mounts directly map container paths to your host filesystem, ensuring migration files are immediately accessible for Git commits.
2. **Transparent Development**: Changes made inside the container are instantly visible in your project files.
3. **Simplified Migration Workflow**: Your production-first migration approach will work seamlessly with your local development environment.

## Changes Required

### 1. Update docker-compose.dev.yml

Replace volume mounts with bind mounts for the PayloadCMS service:

```yaml
volumes:
  # Bind mounts for project code and migrations
  - ./payloadcms-cms-fe-portfolio2025:/app
  - ./payloadcms-cms-fe-portfolio2025/src/migrations:/app/src/migrations
  # Still use volume for node_modules to avoid performance issues
  - payloadcms_node_modules:/app/node_modules
  # Still use volume for .next cache to improve build performance
  - payloadcms_next_cache:/app/.next
```

### 2. Update Dockerfile

Simplify the Dockerfile to work with bind mounts:

- Remove complex build stages that are not needed with bind mounts
- Ensure proper permissions for bind-mounted directories
- Set up the container to expect files to be mounted at runtime

### 3. Update entrypoint.sh

Modify the entrypoint script to work with bind-mounted migrations directory:

- Ensure migrations directory exists and has proper permissions
- Make sure generated migration files are accessible in the host filesystem
- Retain the same migration workflow, but with files stored directly in your project

### 4. Update CI/CD Workflow (b-cms-fe-check-deploy.yml)

Enhance the CI/CD workflow to:

- Create a bind mount for migrations in production
- Fetch migration files from the production server after deployment
- Automatically commit migration files back to the repository

## Implementation Steps

1. Replace your current `docker-compose.dev.yml` with the updated version
2. Update your `Dockerfile` to the simplified version
3. Update `entrypoint.sh` to handle bind-mounted directories
4. Update the CI/CD workflow file to handle migrations with bind mounts
5. Create the migration directory on your production server:
   ```bash
   mkdir -p ~/payload-migrations
   ```

## Testing the Changes

1. Start your development environment:
   ```bash
   docker-compose -f docker-compose.dev.yml up -d
   ```

2. Create a test migration:
   ```bash
   docker exec -it payloadcms-dev-portfolio2025 pnpm run payload:migrate:create --name test
   ```

3. Verify that the migration files appear in your local file system:
   ```bash
   ls -la ./payloadcms-cms-fe-portfolio2025/src/migrations
   ```

4. Run the migrations:
   ```bash
   docker exec -it payloadcms-dev-portfolio2025 pnpm run payload:migrate
   ```

5. Commit the migration files to Git:
   ```bash
   git add ./payloadcms-cms-fe-portfolio2025/src/migrations
   git commit -m "Add test migration"
   git push
   ```

## Production Deployment

When you deploy to production with these changes:

1. The CI/CD process will create a bind mount for migrations on the server
2. PayloadCMS will run migrations in that bind-mounted directory
3. The workflow will fetch migration files back to the repository
4. Migration files will be automatically committed to your repository

This creates a full circle that ensures your migrations are properly tracked in version control, regardless of whether they originated in development or production.