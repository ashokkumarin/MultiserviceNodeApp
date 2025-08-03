@echo off
echo 🧪 Testing Endpoints...
echo.

REM Test API Gateway health endpoint
echo Testing API Gateway health endpoint...
curl -s http://13.233.121.64:3000/health
echo.
echo.

REM Test API Gateway direct endpoint
echo Testing API Gateway direct endpoint...
curl -s http://13.233.121.64:3000/api/message1
echo.
echo.

REM Test Service 1 directly
echo Testing Service 1 directly...
curl -s http://3.111.39.203:3001/message1
echo.
echo.

REM Test Service 2 directly
echo Testing Service 2 directly...
curl -s http://13.201.25.52:3002/message2
echo.
echo.

echo 📋 Summary of test results above.
echo.
echo 💡 If endpoints return errors:
echo 1. Check if services are running in AWS Console
echo 2. Check security group rules
echo 3. Check service logs in CloudWatch
echo 4. The API Gateway proxy might not work in ECS without proper service discovery

pause 