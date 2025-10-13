// Minimal AWS SigV4 signing for Amazon PA-API v5 (Node 18+, ESM)
import crypto from 'crypto';

function hmac(key, data) {
  return crypto.createHmac('sha256', key).update(data, 'utf8').digest();
}
function hash(data) {
  return crypto.createHash('sha256').update(data, 'utf8').digest('hex');
}
function toHex(buffer) {
  return buffer.toString('hex');
}

export function signRequest({ method, service, host, region, path, headers = {}, body = '' }) {
  const accessKey = process.env.PAAPI_ACCESS_KEY;
  const secretKey = process.env.PAAPI_SECRET_KEY;
  if (!accessKey || !secretKey) {
    throw new Error('Missing PAAPI_ACCESS_KEY or PAAPI_SECRET_KEY env vars.');
  }
  const now = new Date();
  const amzdate = now.toISOString().replace(/[:-]|\.\d{3}/g, ''); // YYYYMMDDThhmmssZ
  const datestamp = amzdate.slice(0, 8);

  const canonicalHeaders = Object.entries({
    host,
    'content-type': 'application/json; charset=UTF-8',
    'x-amz-date': amzdate,
    ...headers
  }).map(([k, v]) => [k.toLowerCase(), ('' + v).trim()])
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([k, v]) => `${k}:${v}\n`).join('');
  const signedHeaders = canonicalHeaders.split('\n').filter(Boolean).map(l => l.split(':')[0]).join(';');
  const payloadHash = hash(body);

  const canonicalRequest = [
    method,
    path,
    '',
    canonicalHeaders,
    signedHeaders,
    payloadHash
  ].join('\n');

  const algorithm = 'AWS4-HMAC-SHA256';
  const credentialScope = `${datestamp}/${region}/${service}/aws4_request`;
  const stringToSign = [
    algorithm,
    amzdate,
    credentialScope,
    hash(canonicalRequest)
  ].join('\n');

  const kDate = hmac(Buffer.from('AWS4' + secretKey, 'utf8'), datestamp);
  const kRegion = hmac(kDate, region);
  const kService = hmac(kRegion, service);
  const kSigning = hmac(kService, 'aws4_request');
  const signature = toHex(crypto.createHmac('sha256', kSigning).update(stringToSign, 'utf8').digest());

  const authorization = `${algorithm} Credential=${accessKey}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;

  return {
    amzdate,
    authorization,
    payloadHash,
    signedHeaders
  };
}
