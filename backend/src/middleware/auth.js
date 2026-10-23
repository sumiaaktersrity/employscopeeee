const { supabase } = require('../config/supabase');

/**
 * Verifies the Supabase access token sent as `Authorization: Bearer <token>`,
 * then maps that Supabase account to its row in public."User" (matched by
 * email, created with role 'user' on first login).
 * Every route only depends on `req.userId`, so nothing else must change.
 */
async function requireUser(req, res, next) {
  try {
    const header = req.header('authorization') || '';
    const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';
    if (!token) return res.status(401).json({ error: 'Not logged in' });

    const { data, error } = await supabase.auth.getUser(token);
    const email = data?.user?.email?.toLowerCase();
    if (error || !email) {
      return res.status(401).json({ error: 'Invalid or expired session' });
    }

    let { data: row, error: selErr } = await supabase
      .from('User').select('id').eq('email', email).maybeSingle();
    if (selErr) return next(selErr);

    if (!row) {
      const { data: created, error: insErr } = await supabase
        .from('User').insert({ email, role: 'user' }).select('id').single();
      if (insErr) {
        // Two first requests can race; if the row exists now, use it.
        const { data: again } = await supabase
          .from('User').select('id').eq('email', email).maybeSingle();
        if (!again) return next(insErr);
        row = again;
      } else {
        row = created;
      }
    }

    req.user = { id: row.id, email };
    req.userId = row.id;
    next();
  } catch (err) {
    next(err);
  }
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