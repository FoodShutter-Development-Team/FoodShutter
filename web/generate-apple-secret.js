const jwt = require('jsonwebtoken');
const fs = require('fs');

// 1. 替换成你实际的 .p8 文件名
const privateKey = fs.readFileSync('./AuthKey_9N5W8763P5.p8', 'utf8');

const token = jwt.sign({}, privateKey, {
    algorithm: 'ES256',
    expiresIn: '180d', // 180天后过期
    audience: 'https://appleid.apple.com',
    issuer: 'J82G6TTJ25',
    subject: 'com.foodshutter.app.signin',
    keyid: '9N5W8763P5',
});

console.log("👉 你的 Secret Key 是:\n");
console.log(token);
