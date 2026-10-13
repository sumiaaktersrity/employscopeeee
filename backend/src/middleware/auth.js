const { supabase } = require('../config/supabase');

/**
 * TEMPORARY auth: reads the numeric user id from the `x-user-id` header.
 * Replace the body of `requireUser` with real JWT verification once Login
 * is wired (e.g. supabase.auth.getUser(token) -> map to public."User".id).
 * Every route only depends on `req.userId`, so nothing else must change.
 */
function requireUser(req, res, next) {
  const id = Number(req.header('x-user-id') || 1);

  if (!Number.isSafeInteger(id) || id <= 0) {
    return res.status(401).json({ error: 'Invalid user ID' });
  }

  req.user = { id };
  req.userId = id;

  next();
}

/** Allow only users whose public."User".role is in `roles`. */
function requireRole(...roles) {
  return async (req, res, next) => {
    const { data, error } = await supabase
      .from('User').select('role').eq('id', req.userId).maybeSingle();
    if (error) return next(error);
    const role = (data?.role || '').toLowerCase();
    req.userRole = role;
    if (!roles.includes(role))
      return res.status(403).json({ error: `Requires role: ${roles.join(' or ')}` });
    next();
  };
}

module.exports = { requireUser, requireRole };
