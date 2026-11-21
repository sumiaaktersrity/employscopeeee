// run from backend/:  node --env-file=.env src/testapi.js
const HOST = 'jsearch.p.rapidapi.com';
const KEY = process.env.JSEARCH_API_KEY;
if (!KEY) { console.error('JSEARCH_API_KEY is not set in .env'); process.exit(1); }

(async () => {
  const url = `https://${HOST}/search-v2?` + new URLSearchParams({
    query: 'JavaScript jobs', page: '1', num_pages: '1', country: 'bd',
  });
  const r = await fetch(url, {
    headers: { 'X-RapidAPI-Key': KEY, 'X-RapidAPI-Host': HOST },
    signal: AbortSignal.timeout(15000),
  });
  const text = await r.text();
  console.log('HTTP', r.status, '| quota remaining:', r.headers.get('x-ratelimit-requests-remaining'));

  let body;
  try { body = JSON.parse(text); } catch { console.log(text.slice(0, 500)); return; }

  console.log('top-level keys:', Object.keys(body));
  console.log('typeof data:', typeof body.data, Array.isArray(body.data) ? '(array)' : '');

  let list = null;
  if (Array.isArray(body.data)) list = body.data;
  else if (body.data && typeof body.data === 'object') {
    console.log('data keys:', Object.keys(body.data));
    list = Object.values(body.data).find(Array.isArray) || null;
  }
  console.log('jobs found:', list ? list.length : 'none');
  if (list && list[0]) {
    console.log('first job keys:', Object.keys(list[0]));
    const j = list[0];
    console.log('sample:', {
      job_id: j.job_id, job_title: j.job_title, employer_name: j.employer_name,
      job_location: j.job_location, job_city: j.job_city, job_state: j.job_state,
      job_country: j.job_country, job_apply_link: j.job_apply_link,
      has_description: !!j.job_description,
    });
  } else {
    console.log('raw start:', text.slice(0, 500));
  }
})();