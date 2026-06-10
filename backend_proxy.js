const http = require('http');

const TARGET_HOST = '127.0.0.1';
const TARGET_PORT = 80;
const PROXY_PORT = 8080;

const server = http.createServer((req, res) => {
    console.log(`[PROXY] ${req.method} ${req.url}`);

    const options = {
        hostname: TARGET_HOST,
        port: TARGET_PORT,
        path: req.url,
        method: req.method,
        headers: req.headers
    };

    // Replace host header to avoid Apache issues
    options.headers['host'] = `${TARGET_HOST}:${TARGET_PORT}`;

    const proxyReq = http.request(options, (proxyRes) => {
        res.writeHead(proxyRes.statusCode, proxyRes.headers);
        proxyRes.pipe(res, { end: true });
    });

    req.pipe(proxyReq, { end: true });

    proxyReq.on('error', (err) => {
        console.error(`[PROXY ERROR] ${err.message}`);
        res.statusCode = 502;
        res.end('Proxy Error: Could not reach backend');
    });
});

server.listen(PROXY_PORT, '0.0.0.0', () => {
    console.log(`🚀 VSN Proxy running on port ${PROXY_PORT}`);
    console.log(`🔗 Forwarding to http://${TARGET_HOST}:${TARGET_PORT}`);
    console.log(`📱 Use http://172.25.81.185:8080/vsn_grocery/ in your app`);
});
