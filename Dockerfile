FROM scottw/alpine-perl

WORKDIR /app
COPY cpanfile cpanfile.snapshot /app/
RUN cpanm --installdeps --notest .
COPY kv-mojo /app/

EXPOSE 3000
CMD ["./kv-mojo", "daemon"]
