import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    stages: [
        { duration: '2m', target: 100 },   // Ramp to 100
        { duration: '5m', target: 100 },   // Stay
        { duration: '2m', target: 200 },   // Ramp to 200
        { duration: '5m', target: 200 },   // Stay
        { duration: '2m', target: 300 },   // Ramp to 300
        { duration: '5m', target: 300 },   // Stay
        { duration: '2m', target: 400 },   // Ramp to 400 (breaking point?)
        { duration: '5m', target: 400 },   // Stay
        { duration: '5m', target: 0 },     // Ramp down
    ],
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
    const res = http.get(`${BASE_URL}/api/users`);

    check(res, {
        'status is 200': (r) => r.status === 200,
    });

    sleep(1);
}
