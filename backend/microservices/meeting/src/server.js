const app = require('./app');
const Eureka = require('eureka-js-client').Eureka;

const PORT = process.env.PORT || 8083;

const eurekaClient = new Eureka({
  instance: {
    app: 'MEETING',
    instanceId: `meeting-${PORT}-${process.pid}`,
    hostName: 'localhost',
    ipAddr: '127.0.0.1',
    statusPageUrl: `http://localhost:${PORT}/health`,
    healthCheckUrl: `http://localhost:${PORT}/health`,
    port: { '$': Number(PORT), '@enabled': true },
    vipAddress: 'meeting',
    dataCenterInfo: {
      '@class': 'com.netflix.appinfo.InstanceInfo$DefaultDataCenterInfo',
      name: 'MyOwn'
    }
  },
  eureka: {
    host: 'localhost',
    port: 8761,
    servicePath: '/eureka/apps/'
  }
});

eurekaClient.start();

app.listen(PORT, () => {
  console.log(`meeting microservice running on http://localhost:${PORT}`);
  console.log(`Swagger UI: http://localhost:${PORT}/swagger-ui`);
});
