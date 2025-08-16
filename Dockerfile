FROM nginx:alpine

# Copy static files to nginx html directory
COPY . /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create a simple startup script to handle port configuration
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'sed -i "s/listen 80;/listen 8080;/" /etc/nginx/conf.d/default.conf' >> /start.sh && \
    echo 'nginx -g "daemon off;"' >> /start.sh && \
    chmod +x /start.sh

# Expose port 8080
EXPOSE 8080

# Start nginx with custom configuration
CMD ["/start.sh"]