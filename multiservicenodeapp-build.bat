cd api-gateway
docker build -t api-gateway .
cd ../service1
docker build -t service1 .
cd ../service2
docker build -t service2 .
cd ../
docker-compose up
