export function notFound(req, res) {
  res.status(404).json({ error: `Route not found: ${req.method} ${req.originalUrl}` });
}

export function errorHandler(err, req, res, _next) {
  console.error('[api] error:', err.message);
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'Invalid JSON body' });
  }
  res.status(err.status ?? 500).json({ error: err.message ?? 'Internal server error' });
}

// Minimal field validator: picks listed fields out of the body, returns { clean, errors }.
export function pickFields(body, fields) {
  const clean = {};
  for (const [key, opts] of Object.entries(fields)) {
    const raw = body[key];
    if (opts.required && (raw === undefined || raw === null || raw === '')) {
      return { clean: null, errors: [`Missing required field: ${key}`] };
    }
    if (raw === undefined || raw === null) {
      if (opts.default !== undefined) clean[key] = opts.default;
      continue;
    }
    clean[key] = raw;
  }
  return { clean, errors: [] };
}