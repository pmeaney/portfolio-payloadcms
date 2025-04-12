#!/bin/bash
#
# sync-from-prod.sh
#
# Script to sync your local development environment with production.
# This handles database content, migration files, and media files.
#
# Usage:
#   ./sync-from-prod.sh -s SERVER -u USER
#
# Example:
#   ./sync-from-prod.sh -s 192.168.1.100 -u deploy_user
#   ./sync-from-prod.sh -s example.com -u admin
#
# Options:
#   -s SERVER     Production server IP address or domain name
#   -u USER       SSH username for production server
#   -h            Show help message

# Database configuration
POSTGRES_DB="payloadcms-db"
POSTGRES_USER="payloadcms-user"

# Default values
LOCAL_DB_CONTAINER="pg-dev-payloadcms"
PROD_DB_CONTAINER="payloadcms-postgres-db-portfolio-prod"
MIGRATIONS_PATH="./payloadcms-cms-fe-portfolio2025/src/migrations"
MEDIA_PATH="./payloadcms-cms-fe-portfolio2025/public/media"
LOCAL_BACKUP_DIR="./sync-from-prod--db-backups"
PROD_SERVER=""
PROD_USER=""
COMPOSE_FILE="docker-compose.dev.yml"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display usage information
usage() {
    echo "Usage: $0 -s SERVER -u USER"
    echo ""
    echo "Required arguments:"
    echo "  -s SERVER     Production server IP address or domain name"
    echo "  -u USER       SSH username for production server"
    echo ""
    echo "Optional arguments:"
    echo "  -h            Show this help message"
    exit 1
}

# Parse command line arguments
while getopts ":s:u:h" opt; do
    case ${opt} in
        s)
            PROD_SERVER=$OPTARG
            ;;
        u)
            PROD_USER=$OPTARG
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: $OPTARG" 1>&2
            usage
            ;;
        :)
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            usage
            ;;
    esac
done

# Check required parameters
if [ -z "$PROD_SERVER" ] || [ -z "$PROD_USER" ]; then
    echo -e "${RED}Error: Server and SSH username are required.${NC}"
    usage
fi

# Create local backup directory if it doesn't exist
mkdir -p "$LOCAL_BACKUP_DIR"

# Ensure local containers are running
echo -e "${YELLOW}Checking local containers...${NC}"
if ! docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
    echo -e "${YELLOW}Starting local containers...${NC}"
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Wait for containers to be fully up
    sleep 10
fi

echo "Starting production to local sync process..."
echo "Server: $PROD_SERVER"
echo "Username: $PROD_USER"
echo "Production DB Container: $PROD_DB_CONTAINER"
echo "Local DB Container: $LOCAL_DB_CONTAINER"
echo "Migrations Path: $MIGRATIONS_PATH"
echo "Media Path: $MEDIA_PATH"
echo "Local Backup Directory: $LOCAL_BACKUP_DIR"

# 1. Fetch migration files from production server
echo -e "\n${YELLOW}Fetching migration files from production server...${NC}"
mkdir -p $MIGRATIONS_PATH
ssh $PROD_USER@$PROD_SERVER "cd /home/ghaCICDDevOpsUser/payloadcms-cms-fe-portfolio2025__migrations && tar czf - ." | tar xzf - -C $MIGRATIONS_PATH

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Migration files fetched successfully!${NC}"
    echo -e "  Files saved to: ${MIGRATIONS_PATH}"
else
    echo -e "${RED}✗ Failed to fetch migration files${NC}"
    exit 1
fi

# 2. Fetch media files from production server
echo -e "\n${YELLOW}Fetching media files from production server...${NC}"
mkdir -p $MEDIA_PATH
ssh $PROD_USER@$PROD_SERVER "cd /home/ghaCICDDevOpsUser/payloadcms-cms-fe-portfolio2025__media && tar czf - ." | tar xzf - -C $MEDIA_PATH

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Media files fetched successfully!${NC}"
    echo -e "  Files saved to: ${MEDIA_PATH}"
else
    echo -e "${RED}✗ Failed to fetch media files${NC}"
    exit 1
fi

# 3. Create backup of production database
echo -e "\n${YELLOW}Creating backup of production database...${NC}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILENAME="payload_prod_backup_$TIMESTAMP.sql"

# Ensure backup directory exists
ssh $PROD_USER@$PROD_SERVER "mkdir -p ~/payloadcms-database-backups"

# Run pg_dump in the production database container and save it locally
ssh $PROD_USER@$PROD_SERVER "docker exec $PROD_DB_CONTAINER pg_dump -U $POSTGRES_USER $POSTGRES_DB > ~/payloadcms-database-backups/$BACKUP_FILENAME"
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to create database backup on production server${NC}"
    exit 1
fi

# Download the backup file
echo -e "${YELLOW}Downloading database backup...${NC}"
scp $PROD_USER@$PROD_SERVER:~/payloadcms-database-backups/$BACKUP_FILENAME "$LOCAL_BACKUP_DIR/$BACKUP_FILENAME"
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to download database backup${NC}"
    exit 1
fi

# Clean up remote backup file
ssh $PROD_USER@$PROD_SERVER "rm ~/payloadcms-database-backups/$BACKUP_FILENAME"

echo -e "${GREEN}✓ Production database backup created and downloaded!${NC}"

# 4. Restore production backup to local database
echo -e "\n${YELLOW}Restoring production data to local database...${NC}"
echo -e "${YELLOW}WARNING: This will overwrite your local database. Press CTRL+C to cancel or ENTER to continue${NC}"
read

# Stop local PayloadCMS container to avoid connection issues
echo "Stopping local PayloadCMS container..."
docker-compose -f "$COMPOSE_FILE" stop payloadcms-dev-portfolio2025

# Drop and recreate the database to ensure a clean slate
echo "Recreating local database..."
docker exec $LOCAL_DB_CONTAINER psql -U $POSTGRES_USER -c "DROP DATABASE IF EXISTS $POSTGRES_DB;"
docker exec $LOCAL_DB_CONTAINER psql -U $POSTGRES_USER -c "CREATE DATABASE $POSTGRES_DB;"

# Restore the database from backup
echo "Restoring database from backup..."
cat "$LOCAL_BACKUP_DIR/$BACKUP_FILENAME" | docker exec -i $LOCAL_DB_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Production data successfully restored to local database!${NC}"
else
    echo -e "${RED}✗ Failed to restore production data to local database${NC}"
    exit 1
fi

# 5. Restart local PayloadCMS container
echo -e "\n${YELLOW}Restarting local PayloadCMS container...${NC}"
docker-compose -f "$COMPOSE_FILE" start payloadcms-dev-portfolio2025

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Local PayloadCMS container restarted successfully!${NC}"
else
    echo -e "${RED}✗ Failed to restart local PayloadCMS container${NC}"
    exit 1
fi

echo -e "\n${GREEN}=====================================${NC}"
echo -e "${GREEN}Production to local sync complete!${NC}"
echo -e "${GREEN}Your local environment now mirrors production.${NC}"
echo -e "${GREEN}=====================================${NC}"

# No need to remove the backup file, it's now in a dedicated directory