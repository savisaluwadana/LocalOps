import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    stages: [
        { duration: '10s', target: 100 },  // Fast ramp
        { duration: '1m', target: 100 },   // Stay
        { duration: '10s', target: 1000 }, // SPIKE!
        { duration: '3m', target: 1000 },  // Stay at spike
        { duration: '10s', target: 100 },  // Drop back
        { duration: '3m', target: 100 },   // Recovery
        { duration: '10s', target: 0 },    // Ramp down
    ],
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
    const res = http.get(`${BASE_URL}/`);

    check(res, {
        'status is 200': (r) => r.status === 200,
    });

    sleep(0.5);
}
