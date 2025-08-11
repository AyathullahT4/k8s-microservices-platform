const express = require('express');
const app = express();
app.get('/health', (_, res) => res.status(200).json({ok: true, service: 'node'}));
app.get('/', (_, res) => res.send('Hello from Node'));
app.listen(3000, () => console.log('api-node listening on 3000'));
