const request = require('supertest');
const app = require('./server');

// Lightweight smoke tests that don't require a live database or network
// access to the REST Countries API, so `npm test` works in CI unmodified.
describe('GET /api/health', () => {
  it('responds with a status field', async () => {
    const res = await request(app).get('/api/health');
    expect([200, 503]).toContain(res.statusCode);
    expect(res.body).toHaveProperty('status');
  });
});

describe('POST /api/destinations validation', () => {
  it('rejects a request with no country', async () => {
    const res = await request(app).post('/api/destinations').send({});
    expect(res.statusCode).toBe(400);
  });

  it('rejects a request with a blank country', async () => {
    const res = await request(app).post('/api/destinations').send({ country: '   ' });
    expect(res.statusCode).toBe(400);
  });
});
