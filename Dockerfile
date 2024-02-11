# Use a PHP image with FPM
FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Set working directory
WORKDIR /var/www

# Configure PHP-FPM to listen on TCP/IP instead of Unix socket
RUN sed -i 's/listen = \/run\/php\/php8.2-fpm.sock/listen = 127.0.0.1:9000/' /usr/local/etc/php-fpm.d/zz-docker.conf

# Remove default Nginx configuration
RUN rm /etc/nginx/sites-enabled/default

# Copy Nginx configuration for Laravel
COPY nginx.conf /etc/nginx/sites-available/default
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Copy existing application directory
COPY . /var/www

# Install Composer globally
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install dependencies with Composer
RUN composer install --no-scripts --no-autoloader

# Generate autoload files and optimize
RUN composer dump-autoload --optimize

COPY . /var/www

# Change ownership of our applications
RUN chown -R www-data:www-data /var/www

# change permission
RUN chmod -R 777 /var/www/storage /var/www/bootstrap/cache

# Expose port 80
EXPOSE 80

# Start Nginx and PHP-FPM
CMD ["sh", "-c", "service nginx start && php-fpm"]
