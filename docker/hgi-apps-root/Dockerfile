FROM nginx:alpine

# Remove default nginx static page
RUN rm -rf /usr/share/nginx/html/*

# Copy your HTML and CSS
COPY index.html /usr/share/nginx/html/index.html
COPY hgi.css /usr/share/nginx/html/hgi.css

# Expose port 80
EXPOSE 80

