#!/bin/bash
# WordPress Production Deployment with Docker
echo "🚀 Installing WordPress with Docker - PRODUCTION MODE"

# Configuration
WP_PORT="8080"
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
MYSQL_PASSWORD=$(openssl rand -base64 32)
PROJECT_NAME="wordpress-prod"

# Verify Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Installing first..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker installed. Please log out and log back in."
    exit 1
fi

# Verify docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "📦 Installing docker-compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create project directory
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Create secure environment variables
cat > .env << EOF
# WordPress Production Environment
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
WORDPRESS_DB_HOST=mysql
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=${MYSQL_PASSWORD}
WORDPRESS_DB_NAME=wordpress
WP_PORT=${WP_PORT}
PROJECT_NAME=${PROJECT_NAME}

# Security
WP_DEBUG=false
DISABLE_WP_CRON=false
EOF

# Load environment variables
export $(grep -v '^#' .env | xargs)

# Create docker-compose.yml
cat > docker-compose.yml << EOF
version: "3.8"

services:
  mysql:
    image: mysql:8.0
    container_name: ${PROJECT_NAME}-mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./mysql/conf.d:/etc/mysql/conf.d:ro
    networks:
      - wordpress-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      timeout: 20s
      retries: 10
      start_period: 30s

  wordpress:
    image: wordpress:php8.2-apache
    container_name: ${PROJECT_NAME}-site
    restart: unless-stopped
    ports:
      - "${WP_PORT}:80"
    environment:
      WORDPRESS_DB_HOST: ${WORDPRESS_DB_HOST}
      WORDPRESS_DB_USER: ${WORDPRESS_DB_USER}
      WORDPRESS_DB_PASSWORD: ${WORDPRESS_DB_PASSWORD}
      WORDPRESS_DB_NAME: ${WORDPRESS_DB_NAME}
    depends_on:
      mysql:
        condition: service_healthy
    volumes:
      - wp_data:/var/www/html
      - ./uploads.ini:/usr/local/etc/php/conf.d/uploads.ini
    networks:
      - wordpress-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  mysql_data:
    driver: local
  wp_data:
    driver: local

networks:
  wordpress-network:
    driver: bridge
EOF

# Create directory structure
mkdir -p mysql/conf.d

# MySQL production configuration
cat > mysql/conf.d/my.cnf << 'EOF'
[mysqld]
innodb_buffer_pool_size = 256M
max_connections = 100
EOF

# PHP production configuration
cat > uploads.ini << 'EOF'
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
EOF

# Create backup script
cat > backup.sh << EOF
#!/bin/bash
BACKUP_DIR="./backups"
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)

mkdir -p \$BACKUP_DIR

echo "📦 Creating WordPress backup..."
docker-compose exec mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} wordpress > \$BACKUP_DIR/wordpress_db_\$TIMESTAMP.sql
docker cp ${PROJECT_NAME}-site:/var/www/html \$BACKUP_DIR/wordpress_files_\$TIMESTAMP

tar -czf \$BACKUP_DIR/wordpress_backup_\$TIMESTAMP.tar.gz \$BACKUP_DIR/wordpress_db_\$TIMESTAMP.sql \$BACKUP_DIR/wordpress_files_\$TIMESTAMP

echo "✅ Backup created: \$BACKUP_DIR/wordpress_backup_\$TIMESTAMP.tar.gz"
EOF

chmod +x backup.sh

# Check port availability
if lsof -Pi :$WP_PORT -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Port $WP_PORT is in use. Changing to 8081..."
    sed -i 's/WP_PORT=.*/WP_PORT=8081/' .env
    export WP_PORT="8081"
fi

# Start containers
echo "🐳 Starting containers in production mode..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check status
echo "📊 Checking container status..."
docker-compose ps

# Display security information
echo ""
echo "🔐 SECURITY INFORMATION (SAVE THESE CREDENTIALS):"
echo "   MySQL Root Password: $MYSQL_ROOT_PASSWORD"
echo "   MySQL User Password: $MYSQL_PASSWORD"
echo ""
echo "✅ WordPress installed successfully in PRODUCTION MODE!"
echo "🌐 URL: http://localhost:${WP_PORT}"
echo ""
echo "🔧 MAINTENANCE COMMANDS:"
echo "   ./backup.sh                                    # Create full backup"
echo "   docker-compose logs -f                         # View logs in real-time"
echo "   docker-compose exec mysql mysql -u root -p     # Access MySQL"