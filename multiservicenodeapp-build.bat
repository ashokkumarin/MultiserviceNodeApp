cd api-gateway
docker build -t api-gateway-image .
cd ../service1
docker build -t service1-image .
cd ../service2
docker build -t service2-image .
cd ../
docker-compose up
