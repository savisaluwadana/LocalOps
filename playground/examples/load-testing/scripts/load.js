import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export const options = {
    stages: [
        { duration: '2m', target: 100 },  // Ramp up to 100 users
        { duration: '5m', target: 100 },  // Stay at 100 users
        { duration: '2m', target: 200 },  // Ramp up to 200 users
        { duration: '5m', target: 200 },  // Stay at 200 users
        { duration: '2m', target: 0 },    // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'],  // 95% of requests under 500ms
        errors: ['rate<0.1'],               // Error rate under 10%
    },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
    // Test homepage
    const homeRes = http.get(`${BASE_URL}/`);
    check(homeRes, {
        'homepage status is 200': (r) => r.status === 200,
        'homepage response time < 200ms': (r) => r.timings.duration < 200,
    });

    sleep(1);

    // Test API endpoint
    const apiRes = http.get(`${BASE_URL}/api/users`);
    const apiSuccess = check(apiRes, {
        'API status is 200': (r) => r.status === 200,
        'API returns JSON': (r) => r.headers['Content-Type'].includes('application/json'),
        'API response time < 500ms': (r) => r.timings.duration < 500,
    });

    errorRate.add(!apiSuccess);

    sleep(1);

    // Test POST endpoint
    const payload = JSON.stringify({
        username: `user_${__VU}_${__ITER}`,
        email: `user${__VU}@test.com`,
    });

    const postRes = http.post(`${BASE_URL}/api/users`, payload, {
        headers: { 'Content-Type': 'application/json' },
    });

    check(postRes, {
        'POST status is 201 or 200': (r) => r.status === 201 || r.status === 200,
    });

    sleep(2);
}

export function handleSummary(data) {
    return {
        'summary.json': JSON.stringify(data, null, 2),
        stdout: textSummary(data, { indent: ' ', enableColors: true }),
    };
}

function textSummary(data, options) {
    // Simple text summary
    return `
    ============================================
    LOAD TEST RESULTS
    ============================================
    Total Requests: ${data.metrics.http_reqs.values.count}
    Failed Requests: ${data.metrics.http_req_failed?.values.passes || 0}
    Avg Duration: ${data.metrics.http_req_duration.values.avg.toFixed(2)}ms
    P95 Duration: ${data.metrics.http_req_duration.values['p(95)'].toFixed(2)}ms
    ============================================
    `;
}
