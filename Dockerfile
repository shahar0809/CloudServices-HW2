FROM python:3.8-slim-buster

# Installing python3.8 and pip3
RUN apt-get update  -y
RUN apt-get upgrade -y
RUN apt-get install -y libpq-dev && apt-get -y install gcc

# We copy just the requirements.txt first to leverage Docker cache
COPY web_server/requirements.txt /app/requirements.txt

WORKDIR /app
RUN pip3 install -r requirements.txt

COPY web_server /app

CMD [ "python3", "app.py"]
