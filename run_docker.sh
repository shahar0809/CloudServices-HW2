sudo docker volume create --name db_volume
sudo docker run -d --name postgres -p 5432:5432 \
           --env-file database.conf \
           -v db_volume:/var/lib/postgresql postgres:latest