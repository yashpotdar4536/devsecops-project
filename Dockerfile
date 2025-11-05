# Use a lightweight Nginx image
FROM nginx:alpine

# Remove the default Nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy our custom index.html file
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# The default Nginx command will run
CMD ["nginx","-g","daemon off;"]
